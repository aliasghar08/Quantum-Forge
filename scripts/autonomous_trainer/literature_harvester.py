#!/usr/bin/env python3
"""Autonomous Literature Harvester for Quantum Forge.

Monitors scholarly sources (OpenAlex, CrossRef, arXiv, Europe PMC) for newly
published computational chemistry, reaction kinetics, and transition state research.
Maintains a local SQLite ledger to ensure idempotency and prevent duplicate training.
"""

from __future__ import annotations

import argparse
import datetime
import json
import logging
import os
from pathlib import Path
import random
import sqlite3
import urllib.parse
import urllib.request

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("LiteratureHarvester")

DEFAULT_DB_PATH = Path("data/autonomous_training/literature_ledger.sqlite")


def get_db(db_path: Path = DEFAULT_DB_PATH) -> sqlite3.Connection:
    """Initialize SQLite database with schema if not exists."""
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    with conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS papers (
                doi TEXT PRIMARY KEY,
                title TEXT,
                published_date TEXT,
                source TEXT,
                url TEXT,
                abstract TEXT,
                status TEXT DEFAULT 'pending',
                data_links TEXT,
                discovered_at TEXT,
                updated_at TEXT
            );

            CREATE TABLE IF NOT EXISTS extracted_structures (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                doi TEXT,
                system_name TEXT,
                num_atoms INTEGER,
                elements TEXT,
                num_frames INTEGER,
                energy_unit TEXT,
                extxyz_path TEXT,
                has_ts INTEGER DEFAULT 0,
                FOREIGN KEY (doi) REFERENCES papers (doi)
            );

            CREATE TABLE IF NOT EXISTS training_runs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                run_timestamp TEXT,
                trigger_doi TEXT,
                device TEXT,
                initial_loss REAL,
                final_loss REAL,
                val_mae_ev REAL,
                checkpoint_path TEXT,
                status TEXT,
                FOREIGN KEY (trigger_doi) REFERENCES papers (doi)
            );
            """
        )
    return conn


class LiteratureHarvester:
    """Queries academic search APIs for new transition state and reaction PES research."""

    def __init__(self, db_path: Path = DEFAULT_DB_PATH):
        self.db_path = db_path
        self.conn = get_db(db_path)

    def fetch_json(self, url: str, timeout: int = 15) -> dict | None:
        """Safe HTTP GET with polite User-Agent."""
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "QuantumForge-AutoResearcher/2.0 (mailto:research@quantumforge.org)",
                "Accept": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as response:
                return json.loads(response.read().decode("utf-8"))
        except Exception as exc:
            logger.warning("HTTP fetch failed for %s: %s", url, exc)
            return None

    def search_openalex(self, query: str = "transition state reaction barrier DFT", limit: int = 5) -> list[dict]:
        """Search OpenAlex works for recent chemical reaction and transition state publications."""
        logger.info("Polling OpenAlex for recent reaction dynamics papers: '%s'", query)
        encoded_q = urllib.parse.quote(query)
        # Filter works published recently (sort by publication_date desc)
        url = (
            f"https://api.openalex.org/works?"
            f"search={encoded_q}&"
            f"sort=publication_date:desc&"
            f"per_page={limit}"
        )
        data = self.fetch_json(url)
        if not data or "results" not in data:
            return []

        discovered = []
        for item in data["results"]:
            doi = item.get("doi")
            if not doi:
                doi = f"openalex:{item.get('id', '').split('/')[-1]}"
            else:
                doi = doi.replace("https://doi.org/", "")

            title = item.get("title") or "Untitled Publication"
            pub_date = item.get("publication_date") or str(datetime.date.today())
            landing_url = item.get("doi") or item.get("id") or ""
            
            # Extract possible supplementary or open access data URLs
            data_links = []
            oa = item.get("open_access", {})
            if oa.get("oa_url"):
                data_links.append(oa["oa_url"])

            discovered.append({
                "doi": doi,
                "title": title,
                "published_date": pub_date,
                "source": "OpenAlex",
                "url": landing_url,
                "abstract": item.get("abstract") or "",
                "data_links": json.dumps(data_links),
            })
        return discovered

    def search_crossref(self, query: str = "reaction kinetics activation energy DFT", limit: int = 5) -> list[dict]:
        """Search CrossRef for newly minted chemical physics DOIs."""
        logger.info("Polling CrossRef for chemical kinetics research: '%s'", query)
        encoded_q = urllib.parse.quote(query)
        url = f"https://api.crossref.org/works?query={encoded_q}&sort=published&order=desc&rows={limit}"
        data = self.fetch_json(url)
        if not data or "message" not in data or "items" not in data["message"]:
            return []

        discovered = []
        for item in data["message"]["items"]:
            doi = item.get("DOI")
            if not doi:
                continue

            title = " ".join(item.get("title", [])) or "Untitled Work"
            pub_date = ""
            created = item.get("created", {}).get("date-parts", [[]])[0]
            if created:
                pub_date = "-".join(str(p).zfill(2) for p in created)

            url_landing = item.get("URL") or f"https://doi.org/{doi}"
            data_links = []
            for link in item.get("link", []):
                if "url" in link:
                    data_links.append(link["url"])

            discovered.append({
                "doi": doi,
                "title": title,
                "published_date": pub_date,
                "source": "CrossRef",
                "url": url_landing,
                "abstract": item.get("abstract") or "",
                "data_links": json.dumps(data_links),
            })
        return discovered

    def register_doi(self, doi: str, title: str | None = None, source: str = "Manual-DOI") -> bool:
        """Manually register a user-provided DOI to trigger automated training."""
        clean_doi = doi.strip().replace("https://doi.org/", "")
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()
        
        # Try fetching metadata from CrossRef if title not provided
        if not title:
            meta = self.fetch_json(f"https://api.crossref.org/works/{urllib.parse.quote(clean_doi)}")
            if meta and "message" in meta:
                title = " ".join(meta["message"].get("title", []))
            if not title:
                title = f"Research Paper ({clean_doi})"

        with self.conn:
            cur = self.conn.cursor()
            cur.execute("SELECT status FROM papers WHERE doi = ?", (clean_doi,))
            row = cur.fetchone()
            if row:
                logger.info("DOI %s already in ledger with status: %s", clean_doi, row["status"])
                return False

            cur.execute(
                """
                INSERT INTO papers (doi, title, published_date, source, url, status, discovered_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'pending', ?, ?)
                """,
                (
                    clean_doi,
                    title,
                    str(datetime.date.today()),
                    source,
                    f"https://doi.org/{clean_doi}",
                    now,
                    now,
                ),
            )
            logger.info("Registered new paper DOI: %s ('%s')", clean_doi, title)
            return True

    def poll_for_new_research(self) -> list[str]:
        """Polls scholarly networks and inserts any new papers into the ledger.
        
        Returns:
            list[str]: List of new DOIs registered in this cycle.
        """
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()
        
        # Broad spectrum queries covering previously missing reaction classes:
        # Sulfur/thiol, Phosphate/kinase, Halogen SN2, Pericyclic/Diels-Alder, Radical HAT, Click chemistry
        search_topics = [
            "thiol disulfide exchange transition state DFT",
            "phosphate hydrolysis reaction barrier DFT",
            "SN2 nucleophilic substitution halogen barrier",
            "Diels Alder cycloaddition pericyclic transition state",
            "click chemistry azide alkyne reaction barrier",
            "radical hydrogen atom transfer potential energy surface",
            "minimum energy reaction path transition state DFT",
        ]
        
        # Pick 2 topics per cycle (round-robin / randomized) to keep queries focused and diverse
        chosen_topics = random.sample(search_topics, k=min(3, len(search_topics)))
        all_candidates = []
        for topic in chosen_topics:
            all_candidates.extend(self.search_openalex(topic, limit=2))
            all_candidates.extend(self.search_crossref(topic, limit=2))

        new_dois = []
        with self.conn:
            cur = self.conn.cursor()
            for cand in all_candidates:
                doi = cand["doi"]
                cur.execute("SELECT doi FROM papers WHERE doi = ?", (doi,))
                if cur.fetchone() is not None:
                    continue  # Already seen and tracked

                cur.execute(
                    """
                    INSERT INTO papers (doi, title, published_date, source, url, abstract, status, data_links, discovered_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)
                    """,
                    (
                        doi,
                        cand["title"],
                        cand["published_date"],
                        cand["source"],
                        cand["url"],
                        cand.get("abstract", ""),
                        cand.get("data_links", "[]"),
                        now,
                        now,
                    ),
                )
                logger.info("✨ Discovered new research paper: %s - %s", doi, cand["title"])
                new_dois.append(doi)

        logger.info("Polling complete. %d new research publications registered.", len(new_dois))
        return new_dois

    def get_pending_papers(self) -> list[sqlite3.Row]:
        """Returns all papers pending data extraction and training."""
        with self.conn:
            cur = self.conn.cursor()
            cur.execute("SELECT * FROM papers WHERE status = 'pending' ORDER BY discovered_at ASC")
            return cur.fetchall()

    def update_paper_status(self, doi: str, status: str) -> None:
        """Update paper status (e.g. 'processed', 'trained', 'skipped_no_coordinates')."""
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()
        with self.conn:
            self.conn.execute(
                "UPDATE papers SET status = ?, updated_at = ? WHERE doi = ?",
                (status, now, doi),
            )


def main():
    parser = argparse.ArgumentParser(description="Quantum Forge Literature Harvester")
    parser.add_argument("--poll", action="store_true", help="Poll scholarly APIs for new research")
    parser.add_argument("--doi", type=str, help="Manually register and queue a specific paper DOI")
    parser.add_argument("--list-pending", action="store_true", help="List all pending research papers")
    args = parser.parse_args()

    harvester = LiteratureHarvester()
    if args.doi:
        success = harvester.register_doi(args.doi)
        print(f"Registered DOI: {args.doi} -> {'SUCCESS' if success else 'ALREADY_EXISTS'}")
    elif args.poll:
        new_papers = harvester.poll_for_new_research()
        print(f"Discovered and queued {len(new_papers)} new research items.")
    elif args.list_pending:
        pending = harvester.get_pending_papers()
        print(f"Pending papers in ledger: {len(pending)}")
        for p in pending:
            print(f" - [{p['doi']}] {p['title']} ({p['source']})")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
