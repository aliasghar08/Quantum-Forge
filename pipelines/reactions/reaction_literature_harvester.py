#!/usr/bin/env python3
"""Autonomous Literature Harvester for Quantum Forge.

Monitors scholarly sources (OpenAlex, CrossRef, arXiv, Europe PMC) for newly
published computational chemistry, reaction kinetics, and transition state research.
Maintains a local SQLite ledger to ensure idempotency and prevent duplicate training.
"""

from __future__ import annotations

import argparse
import collections
import concurrent.futures
import datetime
import json
import logging
import os
from pathlib import Path
import queue
import random
import re
import sqlite3
import threading
import time
import urllib.parse
import urllib.request
from typing import Any, Dict, List, Optional

from scholarly_verifier import ScholarlyReactionVerifier

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("LiteratureHarvester")

DEFAULT_DB_PATH = Path("data/autonomous_training/literature_ledger.sqlite")


class DomainRateLimiter:
    """Thread-safe rate limiter enforcing max requests per second per domain."""

    def __init__(self, calls_per_second: float):
        self.min_interval = 1.0 / max(0.001, calls_per_second)
        self.last_call = 0.0
        self.lock = threading.Lock()

    def wait(self):
        with self.lock:
            now = time.monotonic()
            elapsed = now - self.last_call
            if elapsed < self.min_interval:
                time.sleep(self.min_interval - elapsed)
            self.last_call = time.monotonic()


# Domain-specific rate limiters
_CROSSREF_LIMITER = DomainRateLimiter(10.0)      # 10 req/s
_OPENALEX_LIMITER = DomainRateLimiter(10.0)      # 10 req/s
_EUROPEPMC_LIMITER = DomainRateLimiter(5.0)       # 5 req/s
_ARXIV_LIMITER = DomainRateLimiter(1.0 / 3.0)     # 1 req / 3s


class LedgerWriter(threading.Thread):
    """Single-writer background worker thread consuming from a Queue to eliminate SQLite write locks."""

    def __init__(self, db_path: Path):
        super().__init__(name="LedgerWriter", daemon=True)
        self.db_path = db_path
        self.queue: queue.Queue = queue.Queue()
        self._stop_event = threading.Event()
        self.start()

    def run(self):
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(self.db_path), timeout=60.0)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL;")
            conn.execute("PRAGMA synchronous=NORMAL;")
            conn.execute("PRAGMA busy_timeout=60000;")
        except Exception as e:
            logger.warning("Could not configure SQLite pragmas: %s", e)

        while not (self._stop_event.is_set() and self.queue.empty()):
            try:
                task = self.queue.get(timeout=0.2)
            except queue.Empty:
                continue

            if task is None:
                self.queue.task_done()
                break

            sql, params, event, result_box = task
            try:
                with conn:
                    cur = conn.cursor()
                    cur.execute(sql, params)
                    if result_box is not None:
                        result_box["rowcount"] = cur.rowcount
                        result_box["lastrowid"] = cur.lastrowid
            except Exception as e:
                logger.error("LedgerWriter error executing '%s': %s", sql, e)
                if result_box is not None:
                    result_box["error"] = e
            finally:
                if event:
                    event.set()
                self.queue.task_done()

        try:
            conn.close()
        except Exception:
            pass

    def submit(self, sql: str, params: tuple = (), wait: bool = True) -> Any:
        event = threading.Event() if wait else None
        result_box = {} if wait else None
        self.queue.put((sql, params, event, result_box))
        if wait:
            event.wait()
            if "error" in result_box:
                raise result_box["error"]
            return result_box
        return None

    def flush(self):
        self.queue.join()

    def stop(self):
        self._stop_event.set()
        self.queue.put(None)
        self.join(timeout=5.0)


_LEDGER_WRITERS: Dict[str, LedgerWriter] = {}
_LEDGER_LOCK = threading.Lock()


def get_ledger_writer(db_path: Path = DEFAULT_DB_PATH) -> LedgerWriter:
    with _LEDGER_LOCK:
        resolved = str(db_path.resolve())
        if resolved not in _LEDGER_WRITERS or not _LEDGER_WRITERS[resolved].is_alive():
            _LEDGER_WRITERS[resolved] = LedgerWriter(db_path)
        return _LEDGER_WRITERS[resolved]


def get_db(db_path: Path = DEFAULT_DB_PATH) -> sqlite3.Connection:
    """Initialize SQLite database with schema if not exists with WAL mode enabled."""
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path), timeout=60.0)
    conn.row_factory = sqlite3.Row
    try:
        conn.execute("PRAGMA journal_mode=WAL;")
        conn.execute("PRAGMA synchronous=NORMAL;")
        conn.execute("PRAGMA busy_timeout=60000;")
    except Exception:
        pass
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
                updated_at TEXT,
                citation_count INTEGER DEFAULT 0,
                journal TEXT DEFAULT '',
                is_peer_reviewed INTEGER DEFAULT 1
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
        for col_def in (
            "ALTER TABLE papers ADD COLUMN citation_count INTEGER DEFAULT 0",
            "ALTER TABLE papers ADD COLUMN journal TEXT DEFAULT ''",
            "ALTER TABLE papers ADD COLUMN is_peer_reviewed INTEGER DEFAULT 1",
        ):
            try:
                conn.execute(col_def)
            except sqlite3.OperationalError:
                pass
    return conn



def is_proper_clinical_medicine(title: str, journal: str = "") -> bool:
    """Strictly filters for human clinical pharmacology, therapeutics, and doctor-prescribed medicines.
    
    Rejects non-medical fields (pedagogy, linguistics, LLMs, social media, concrete, finance, etc.).
    """
    text = f"{title} {journal}".lower()
    
    # 1. Non-medical rejection keywords
    disallowed = [
        "chatgpt", "large language model", "llm", "l2 writing", "learner engagement",
        "pedagogy", "social media", "concrete", "mortar", "blockchain", "cryptocurrency",
        "deep learning for text", "sentiment analysis", "curriculum development",
        "game-based", "cqpf", "student engagement", "higher education teaching",
        "facial recognition", "natural language processing", "pedagogical"
    ]
    if any(d in text for d in disallowed):
        return False
        
    # 2. Positive clinical pharmacology & doctor-prescribed medicine keywords + WHO INN drug stems
    clinical_keywords = [
        "pharmac", "drug", "medicin", "receptor", "inhibitor", "inhibit", "antagonist", "agonist",
        "cardio", "cardiac", "cardiovascular", "renal", "nephro", "heart failure", "hypertension", "diuretic",
        "myocardial", "arrhythmia", "statin", "calcineurin", "transplant",
        "antibiotic", "antimicrobial", "antiviral", "chemotherapy", "oncology",
        "endocrin", "diabetes", "insulin", "sglt2", "glp-1", "beta-blocker",
        "calcium channel", "toxicology", "toxic", "poison", "antidote", "metabolism", "cyp450", "cyp", "cytochrome",
        "clearance", "plasma", "serum", "clinical", "patient", "pathophysiology",
        "vasodilat", "vasoconstrict", "adverse", "dosing", "therapeutic", "therapy",
        "acetylcholinesterase", "cholinesterase", "kinase", "synthase", "biochem",
        "synthesis", "derivative", "analog", "congener", "transporter", "channel",
        # Standard WHO INN pharmacological drug stems & active moieties
        "sartan", "pril", "olol", "dipine", "gliflozin", "glutide", "cillin", "mycin",
        "floxacin", "oxacin", "mab", "nib", "zole", "prazole", "tidine", "terol",
        "sacubitril", "valsartan", "enalapril", "metoprolol", "amlodipine", "atorvastatin",
        "dapagliflozin", "spironolactone", "tacrolimus", "vancomycin", "ceftriaxone",
        "aspirin", "warfarin", "apixaban", "amiodarone", "digoxin", "furosemide",
        "naloxone", "atropine", "paracetamol", "acetaminophen", "metformin"
    ]
    return any(ck in text for ck in clinical_keywords)


class LiteratureHarvester:
    """Queries academic search APIs for new transition state and reaction PES research."""

    def __init__(self, db_path: Path = DEFAULT_DB_PATH):
        self.db_path = db_path
        self.conn = get_db(db_path)
        self.writer = get_ledger_writer(db_path)
        self.verifier = ScholarlyReactionVerifier()

    def flush_ledger(self):
        """Ensure all pending ledger write operations are fully written and committed."""
        self.writer.flush()

    def fetch_json(self, url: str, timeout: int = 15) -> dict | None:
        """Safe HTTP GET with polite User-Agent."""
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "QuantumForge-AutoResearcher/2.0 (mailto:aliasgharinnocent@yahoo.com)",
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
        """Search OpenAlex works for recent chemical reaction and transition state publications with domain rate limiting."""
        _OPENALEX_LIMITER.wait()
        logger.info("Polling OpenAlex for recent reaction dynamics papers: '%s'", query)
        encoded_q = urllib.parse.quote(query)
        # Filter works published recently (sort by publication_date desc)
        url = (
            f"https://api.openalex.org/works?"
            f"search={encoded_q}&"
            f"sort=publication_date:desc&"
            f"per_page={limit}&"
            f"mailto=aliasgharinnocent@yahoo.com"
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
                "abstract": "",  # Storing uncopyrightable scientific metadata only
                "data_links": json.dumps(data_links),
            })
        return discovered

    def search_crossref(self, query: str = "reaction kinetics activation energy DFT", limit: int = 5) -> list[dict]:
        """Search CrossRef for newly minted chemical physics DOIs with domain rate limiting."""
        _CROSSREF_LIMITER.wait()
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
                "abstract": "",  # Storing uncopyrightable scientific metadata only
                "data_links": json.dumps(data_links),
            })
        return discovered

    def search_europepmc(self, query: str = "cardiology nephrology pharmacology", limit: int = 5) -> list[dict]:
        """Search Europe PMC / PubMed Central for peer-reviewed biomedical and clinical pharmacology papers with rate limiting."""
        _EUROPEPMC_LIMITER.wait()
        logger.info("Polling Europe PMC for physician-prescribed clinical pharmacology: '%s'", query)
        encoded_q = urllib.parse.quote(query + " AND (SRC:MED OR SRC:PMC)")
        url = f"https://www.ebi.ac.uk/europepmc/webservices/rest/search?query={encoded_q}&format=json&pageSize={limit}&resultType=core"
        data = self.fetch_json(url)
        if not data or "resultList" not in data or "result" not in data["resultList"]:
            return []

        discovered = []
        for item in data["resultList"]["result"]:
            doi = item.get("doi")
            if not doi:
                pmid = item.get("pmid")
                if pmid:
                    doi = f"pmid:{pmid}"
                else:
                    continue

            title = item.get("title", "").rstrip(".")
            pub_date = item.get("firstPublicationDate") or item.get("pubYear") or str(datetime.date.today())
            journal = item.get("journalTitle") or item.get("journalInfo", {}).get("journal", {}).get("title", "")
            
            discovered.append({
                "doi": doi,
                "title": title,
                "published_date": str(pub_date),
                "source": "EuropePMC",
                "url": f"https://doi.org/{doi}" if not doi.startswith("pmid:") else f"https://pubmed.ncbi.nlm.nih.gov/{doi.split(':')[1]}/",
                "journal": journal,
                "data_links": "[]",
            })
        return discovered

    def is_doi_in_firestore(self, clean_doi: str, project_id: str = "quantom-forge") -> bool:
        """Checks if DOI is already published to Firestore /library (for ephemeral cloud containers)."""
        safe_id = "lit_" + clean_doi.replace("/", "_").replace(":", "_").replace(".", "_")
        url = f"https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents/library/{safe_id}"
        try:
            from scholarly_verifier import get_gcloud_auth_token
            token = get_gcloud_auth_token()
            if not token:
                return False
            req = urllib.request.Request(
                url,
                headers={"Authorization": f"Bearer {token}"},
                method="GET",
            )
            with urllib.request.urlopen(req, timeout=5) as resp:
                if resp.status == 200:
                    return True
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return False
        except Exception:
            pass
        return False

    def register_doi(self, doi: str, title: str | None = None, source: str = "Manual-DOI") -> bool:
        """Manually register a user-provided DOI to trigger automated training."""
        clean_doi = doi.strip().replace("https://doi.org/", "")
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()

        # 1. Fast local SQLite check FIRST (0 network overhead)
        with self.conn:
            cur = self.conn.cursor()
            cur.execute("PRAGMA journal_mode=WAL;")
            cur.execute("SELECT status FROM papers WHERE LOWER(doi) = LOWER(?)", (clean_doi,))
            row = cur.fetchone()
            if row:
                logger.info("DOI %s already in ledger with status: %s", clean_doi, row["status"])
                return False

        # 2. Cloud Firestore check (for ephemeral Cloud Run containers where local sqlite is fresh)
        if self.is_doi_in_firestore(clean_doi):
            logger.info("DOI %s already exists in Firestore /library. Recording as trained in local ledger.", clean_doi)
            self.writer.submit(
                "INSERT OR REPLACE INTO papers (doi, title, published_date, source, url, status, discovered_at, updated_at) "
                "VALUES (?, ?, ?, ?, ?, 'trained', ?, ?)",
                (clean_doi, title or f"Research Paper ({clean_doi})", str(datetime.date.today()), source, f"https://doi.org/{clean_doi}", now, now),
                wait=True
            )
            return False

        # 3. Only hit CrossRef + OpenAlex for genuinely unseen DOIs
        verified = self.verifier.verify_doi_and_citations(clean_doi)
        citation_count = 0
        journal = ""
        is_peer_reviewed = 1
        if verified:
            if verified.get("is_retracted"):
                logger.warning("Paper %s is marked as RETRACTED. Rejecting.", clean_doi)
                return False
            title = verified.get("title") or title
            journal = verified.get("journal", "")
            citation_count = verified.get("citation_count", 0)
            is_peer_reviewed = 1 if verified.get("is_peer_reviewed") else 0
        elif not title:
            meta = self.fetch_json(f"https://api.crossref.org/works/{urllib.parse.quote(clean_doi)}")
            if meta and "message" in meta:
                title = " ".join(meta["message"].get("title", []))
            if not title:
                title = f"Research Paper ({clean_doi})"

        self.writer.submit(
            """
            INSERT INTO papers (doi, title, published_date, source, url, status, discovered_at, updated_at, citation_count, journal, is_peer_reviewed)
            VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?)
            """,
            (
                clean_doi,
                title,
                str(datetime.date.today()),
                source,
                f"https://doi.org/{clean_doi}",
                now,
                now,
                citation_count,
                journal,
                is_peer_reviewed,
            ),
            wait=True
        )
        logger.info("Registered and authenticated paper DOI: %s ('%s', %d citations)", clean_doi, title, citation_count)
        return True

    def poll_for_new_research(self) -> list[str]:
        """Polls scholarly networks concurrently, verifies academic authenticity, and queues papers.
        
        Returns:
            list[str]: List of new verified DOIs registered in this cycle.
        """
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()
        
        search_topics = [
            # ── 1. Cardiology & Hemodynamics (Core Priority) ──
            "angiotensin receptor neprilysin inhibitor sacubitril valsartan kinetics",
            "SGLT2 inhibitor dapagliflozin cardiovascular renal mechanism DFT",
            "beta adrenergic blocker metoprolol receptor binding transition state",
            "calcium channel blocker amlodipine dihydropyridine smooth muscle",
            "nitroglycerin organic nitrate ALDH-2 mitochondrial bioactivation DFT",
            "amiodarone potassium channel hERG block arrhythmia transition state",
            "clopidogrel P2Y12 receptor active thiol metabolite disulfide formation",
            "digoxin cardiac glycoside Na-K-ATPase inhibition mechanism",
            "adenosine A1 purinergic receptor AV nodal conduction kinetics",
            "HMG-CoA reductase statin mevaldyl intermediate transition state",
            "PCSK9 inhibitor LDL receptor recycling kinetics",
            "angiotensin converting enzyme ACE inhibitor catalytic zinc mechanism",
            
            # ── 2. Nephrology & Renal Pharmacokinetics (Core Priority) ──
            "mineralocorticoid receptor antagonist spironolactone eplerenone",
            "loop diuretic furosemide NKCC2 cotransporter renal kinetics",
            "thiazide diuretic NCCT sodium chloride cotransporter mechanism",
            "carbonic anhydrase inhibitor acetazolamide zinc coordination DFT",
            "calcineurin inhibitor tacrolimus FKBP12 NFAT dephosphorylation",
            "phosphate binder sevelamer amine binding equilibrium CKD",
            "calcimimetic cinacalcet calcium sensing receptor parathyroid",
            "vasopressin V2 receptor antagonist tolvaptan aquaresis mechanism",
            "tubuloglomerular feedback macula densa adenosine afferent arteriole",
            "renal proximal tubule organic anion transporter OAT1 clearance",
            
            # ── 3. Critical Care, Emergency & Toxicology ──
            "naloxone mu opioid receptor competitive antagonism kinetics",
            "atropine muscarinic acetylcholine receptor M2 antagonism",
            "pralidoxime acetylcholinesterase oxime reactivation transition state",
            "N-acetylcysteine paracetamol NAPQI glutathione conjugation",
            "organophosphate sarin soman acetylcholinesterase phosphorylation",
            
            # ── 4. Antimicrobial Resistance & Infectious Diseases ──
            "vancomycin D-alanyl-D-alanine cell wall transpeptidase barrier",
            "beta-lactamase antibiotic resistance hydrolysis transition state",
            "fluoroquinolone ciprofloxacin bacterial DNA gyrase cleavage complex",
            "cephalosporin ceftriaxone penicillin binding protein acylation",
            "carbapenem metallo-beta-lactamase NDM-1 zinc hydrolysis barrier",
            
            # ── 5. Neurology, Endocrinology & Metabolism ──
            "cytochrome P450 CYP2D6 CYP2C9 drug metabolism oxidation mechanism DFT",
            "GLP-1 receptor agonist semaglutide incretin degradation DPP-4",
            "levetiracetam synaptic vesicle protein SV2A binding kinetics",
            "levodopa aromatic L-amino acid decarboxylase PLP mechanism DFT",
            "donepezil central acetylcholinesterase inhibition crystal structure",
            "metformin mitochondrial complex I AMP-activated protein kinase",
        ]
        
        # Pick 3 topics per cycle (round-robin / randomized)
        chosen_topics = random.sample(search_topics, k=min(3, len(search_topics)))
        all_candidates = []

        # Concurrent search dispatch across chosen topics and sources
        def execute_topic_searches(topic: str) -> list[dict]:
            res = []
            try:
                res.extend(self.search_openalex(topic, limit=2))
            except Exception as e:
                logger.warning("OpenAlex search error for '%s': %s", topic, e)
            try:
                res.extend(self.search_crossref(topic, limit=2))
            except Exception as e:
                logger.warning("CrossRef search error for '%s': %s", topic, e)
            try:
                res.extend(self.search_europepmc(topic, limit=2))
            except Exception as e:
                logger.warning("EuropePMC search error for '%s': %s", topic, e)
            return res

        with concurrent.futures.ThreadPoolExecutor(max_workers=min(8, len(chosen_topics) * 3)) as search_pool:
            futures = [search_pool.submit(execute_topic_searches, topic) for topic in chosen_topics]
            for fut in concurrent.futures.as_completed(futures):
                try:
                    all_candidates.extend(fut.result())
                except Exception as exc:
                    logger.warning("Error fetching topic batch: %s", exc)

        # Filter candidate duplicates and non-clinical records
        unique_candidates = {}
        for cand in all_candidates:
            doi = cand.get("doi")
            if not doi or doi in unique_candidates:
                continue
            title = cand.get("title", "")
            journal = cand.get("journal", "")
            if not is_proper_clinical_medicine(title, journal):
                continue
            unique_candidates[doi] = cand

        # Check local ledger
        unseen_candidates = []
        with self.conn:
            cur = self.conn.cursor()
            for doi, cand in unique_candidates.items():
                cur.execute("SELECT doi FROM papers WHERE LOWER(doi) = LOWER(?)", (doi,))
                if cur.fetchone() is None:
                    unseen_candidates.append(cand)

        # Concurrent verification across unseen candidate DOIs
        new_dois = []
        def verify_candidate(cand: dict) -> Optional[dict]:
            doi = cand["doi"]
            if self.is_doi_in_firestore(doi):
                logger.info("DOI %s already in Firestore /library. Skipping.", doi)
                self.writer.submit(
                    "INSERT OR REPLACE INTO papers (doi, title, published_date, source, url, status, discovered_at, updated_at) "
                    "VALUES (?, ?, ?, ?, ?, 'trained', ?, ?)",
                    (doi, cand.get("title") or f"Research Paper ({doi})", str(datetime.date.today()), cand.get("source", "Crossref"), f"https://doi.org/{doi}", now, now),
                    wait=False
                )
                return None

            v = self.verifier.verify_doi_and_citations(doi)
            if v and v.get("is_retracted"):
                logger.warning("Skipping retracted publication: %s", doi)
                return None

            citation_count = v.get("citation_count", 0) if v else 0
            journal = v.get("journal", "") if v else cand.get("journal", "")
            is_peer_reviewed = 1 if (v and v.get("is_peer_reviewed")) else 1
            title = (v.get("title") if v else None) or cand["title"]

            return {
                "doi": doi,
                "title": title,
                "published_date": cand["published_date"],
                "source": cand["source"],
                "url": cand["url"],
                "abstract": "",
                "data_links": cand.get("data_links", "[]"),
                "discovered_at": now,
                "updated_at": now,
                "citation_count": citation_count,
                "journal": journal,
                "is_peer_reviewed": is_peer_reviewed,
            }

        if unseen_candidates:
            with concurrent.futures.ThreadPoolExecutor(max_workers=min(8, len(unseen_candidates))) as verifier_pool:
                verify_futures = [verifier_pool.submit(verify_candidate, c) for c in unseen_candidates]
                for vf in concurrent.futures.as_completed(verify_futures):
                    try:
                        record = vf.result()
                        if record:
                            self.writer.submit(
                                """
                                INSERT INTO papers (doi, title, published_date, source, url, abstract, status, data_links, discovered_at, updated_at, citation_count, journal, is_peer_reviewed)
                                VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?, ?)
                                """,
                                (
                                    record["doi"],
                                    record["title"],
                                    record["published_date"],
                                    record["source"],
                                    record["url"],
                                    record["abstract"],
                                    record["data_links"],
                                    record["discovered_at"],
                                    record["updated_at"],
                                    record["citation_count"],
                                    record["journal"],
                                    record["is_peer_reviewed"],
                                ),
                                wait=True
                            )
                            logger.info("✨ Discovered & authenticated research paper: %s - %s (%d citations)", record["doi"], record["title"], record["citation_count"])
                            new_dois.append(record["doi"])
                    except Exception as ve:
                        logger.warning("Verification error for candidate: %s", ve)

        self.writer.flush()
        logger.info("Polling complete. %d new research publications registered.", len(new_dois))
        return new_dois

    def get_pending_papers(self) -> list[sqlite3.Row]:
        """Returns all papers pending data extraction and training."""
        with self.conn:
            cur = self.conn.cursor()
            cur.execute("SELECT * FROM papers WHERE status = 'pending' ORDER BY discovered_at ASC")
            return cur.fetchall()

    def update_paper_status(self, doi: str, status: str) -> None:
        """Update paper status (e.g. 'processed', 'trained', 'skipped_no_coordinates') via LedgerWriter."""
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()
        self.writer.submit(
            "UPDATE papers SET status = ?, updated_at = ? WHERE doi = ?",
            (status, now, doi),
            wait=True
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
