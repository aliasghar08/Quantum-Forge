#!/usr/bin/env python3
"""Autonomous 24/7 Background Supervisor Daemon for Quantum Forge.

Watches academic networks for newly published research and DOIs, automatically
ingests reaction coordinates, builds zero-leakage splits, and trains the model
using the local Mac's processor and Metal GPU (MPS) 24/7.
"""

from __future__ import annotations

import argparse
import datetime
import logging
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import time

from literature_harvester import LiteratureHarvester, DEFAULT_DB_PATH, get_db
from data_ingester import DataIngester
from mps_trainer import ContinualTrainer, get_device

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("AutoSupervisor")

LOG_DIR = Path("logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LAUNCHAGENT_NAME = "com.quantumforge.autotrainer"
LAUNCHAGENT_PLIST = Path.home() / f"Library/LaunchAgents/{LAUNCHAGENT_NAME}.plist"


class AutonomousDaemon:
    """End-to-end autonomous research discovery and training supervisor."""

    def __init__(self, poll_interval_hours: float = 6.0):
        self.poll_interval_seconds = int(poll_interval_hours * 3600)
        self.harvester = LiteratureHarvester()
        self.ingester = DataIngester()
        self.device = get_device()

    def run_cycle(self, specific_doi: str | None = None) -> bool:
        """Executes one complete research discovery -> ingestion -> training cycle.
        
        Returns:
            bool: True if training was triggered and completed, False otherwise.
        """
        logger.info("=======================================================")
        logger.info("🚀 Starting Autonomous Research & Training Cycle")
        logger.info("Device acceleration: %s", self.device)
        logger.info("=======================================================")

        new_dois = []
        if specific_doi:
            logger.info("Manual DOI injection: %s", specific_doi)
            if self.harvester.register_doi(specific_doi):
                new_dois.append(specific_doi)
        else:
            new_dois = self.harvester.poll_for_new_research()

        pending_papers = self.harvester.get_pending_papers()
        if not pending_papers:
            logger.info("No pending research papers in ledger. Model is up-to-date. Resting.")
            return False

        logger.info("Found %d pending research papers to ingest.", len(pending_papers))
        extracted_paths = []
        processed_dois = []

        for paper in pending_papers:
            doi = paper["doi"]
            extxyz_path = self.ingester.ingest_paper(paper)
            if extxyz_path and extxyz_path.is_file():
                extracted_paths.append(extxyz_path)
                processed_dois.append(doi)
            else:
                self.harvester.update_paper_status(doi, "skipped_no_coordinates")

        if not extracted_paths:
            logger.warning("No valid structures extracted from pending papers.")
            return False

        # Build zero-leakage training and validation splits with replay buffer
        logger.info("Building zero-leakage continual learning splits...")
        train_path, val_path = self.ingester.build_continual_training_splits(extracted_paths)

        # Execute training on Apple Silicon Metal GPU / multi-core CPU
        trigger_label = processed_dois[0] if len(processed_dois) == 1 else f"batch_{len(processed_dois)}_papers"
        logger.info("Triggering MPS continual training cycle for: %s", trigger_label)

        trainer = ContinualTrainer()
        results = trainer.train_cycle(
            train_path=train_path,
            val_path=val_path,
            trigger_doi=trigger_label,
            epochs=15,
            batch_size=8,
        )

        if results.get("status") == "success":
            logger.info("✅ Training completed successfully. Marking papers as trained in ledger.")
            for doi in processed_dois:
                self.harvester.update_paper_status(doi, "trained")
            return True
        else:
            logger.warning("Training cycle failed or skipped: %s", results)
            return False

    def start_loop(self) -> None:
        """Runs the daemon loop 24/7."""
        logger.info("Starting 24/7 autonomous background daemon (polling every %.1f hours)...", self.poll_interval_seconds / 3600)
        try:
            while True:
                try:
                    self.run_cycle()
                except Exception as exc:
                    logger.error("Error in autonomous cycle: %s", exc, exc_info=True)

                logger.info("Cycle finished. Next check in %d seconds (~%.1f hours).", self.poll_interval_seconds, self.poll_interval_seconds / 3600)
                time.sleep(self.poll_interval_seconds)
        except KeyboardInterrupt:
            logger.info("Daemon stopped by user.")


def print_status() -> None:
    """Print comprehensive summary of autonomous learning status."""
    device = get_device()
    conn = get_db()
    with conn:
        cur = conn.cursor()
        cur.execute("SELECT status, count(*) as cnt FROM papers GROUP BY status")
        paper_counts = {r["status"]: r["cnt"] for r in cur.fetchall()}

        cur.execute("SELECT count(*) as cnt FROM extracted_structures")
        struct_count = cur.fetchone()["cnt"]

        cur.execute("SELECT * FROM training_runs ORDER BY id DESC LIMIT 5")
        recent_runs = cur.fetchall()

    print("\n=======================================================")
    print("   QUANTUM FORGE AUTONOMOUS RESEARCH & LEARNING SYSTEM")
    print("=======================================================")
    print(f"Hardware Acceleration : {device}")
    print(f"Host Machine          : Apple Silicon (24/7 background mode)")
    print(f"Scholarly Ledger      : {DEFAULT_DB_PATH}")
    print("-------------------------------------------------------")
    print("Tracked Research Papers:")
    print(f"  • Trained           : {paper_counts.get('trained', 0)}")
    print(f"  • Pending Ingestion : {paper_counts.get('pending', 0)}")
    print(f"  • Total Evaluated   : {sum(paper_counts.values())}")
    print(f"Extracted Structures  : {struct_count} reaction profiles")
    print("-------------------------------------------------------")
    print("Recent Continual Learning Runs:")
    if recent_runs:
        for r in recent_runs:
            print(f"  • [{r['run_timestamp']}] Trigger: {r['trigger_doi']}")
            print(f"    Device: {r['device']} | Initial Loss: {r['initial_loss']:.4f} | Final Loss: {r['final_loss']:.4f}")
            print(f"    Checkpoint: {r['checkpoint_path']}")
    else:
        print("  (No training runs recorded yet)")
    print("=======================================================\n")


def install_launchd_service() -> None:
    """Installs a macOS launchd agent to ensure this runs 24/7 in the background across reboots."""
    script_path = Path(__file__).resolve()
    repo_dir = script_path.parent.parent.parent.resolve()
    venv_python = (repo_dir / ".venv/bin/python").absolute()
    stdout_log = repo_dir / "logs/autotrainer_stdout.log"
    stderr_log = repo_dir / "logs/autotrainer_stderr.log"

    plist_data = {
        "Label": LAUNCHAGENT_NAME,
        "ProgramArguments": [
            str(venv_python),
            str(script_path),
            "--daemon",
            "--interval",
            "6",
        ],
        "WorkingDirectory": str(repo_dir),
        "KeepAlive": True,
        "RunAtLoad": True,
        "StandardOutPath": str(stdout_log),
        "StandardErrorPath": str(stderr_log),
        "EnvironmentVariables": {
            "PYTORCH_ENABLE_MPS_FALLBACK": "1",
            "PYTHONPATH": f"{repo_dir}:{repo_dir / 'scripts/autonomous_trainer'}",
            "PATH": os.environ.get("PATH", "/usr/bin:/bin:/usr/sbin:/sbin"),
        },
    }

    LAUNCHAGENT_PLIST.parent.mkdir(parents=True, exist_ok=True)
    with open(LAUNCHAGENT_PLIST, "wb") as f:
        plistlib.dump(plist_data, f)

    logger.info("Created LaunchAgent plist at %s", LAUNCHAGENT_PLIST)
    # Load the agent
    subprocess.run(["launchctl", "unload", str(LAUNCHAGENT_PLIST)], capture_output=True)
    res = subprocess.run(["launchctl", "load", "-w", str(LAUNCHAGENT_PLIST)], capture_output=True, text=True)
    if res.returncode == 0:
        logger.info("🎉 24/7 background service registered and loaded into macOS launchd.")
        logger.info("Logs are written to: %s", stdout_log)
    else:
        logger.warning("launchctl load warning: %s", res.stderr)


def uninstall_launchd_service() -> None:
    """Unloads and deletes the macOS launchd LaunchAgent."""
    if LAUNCHAGENT_PLIST.exists():
        subprocess.run(["launchctl", "unload", str(LAUNCHAGENT_PLIST)], capture_output=True)
        LAUNCHAGENT_PLIST.unlink()
        logger.info("Removed LaunchAgent %s", LAUNCHAGENT_NAME)
    else:
        logger.info("LaunchAgent plist does not exist.")


def main():
    parser = argparse.ArgumentParser(description="Quantum Forge 24/7 Autonomous Trainer Daemon")
    parser.add_argument("--run-once", action="store_true", help="Execute an immediate research discovery and training cycle")
    parser.add_argument("--daemon", action="store_true", help="Run continuously in the background")
    parser.add_argument("--interval", type=float, default=6.0, help="Polling interval in hours (default: 6.0)")
    parser.add_argument("--ingest-doi", type=str, help="Ingest a specific paper DOI and train immediately")
    parser.add_argument("--status", action="store_true", help="Print ledger status and training history")
    parser.add_argument("--install-service", action="store_true", help="Install macOS launchd 24/7 background service")
    parser.add_argument("--uninstall-service", action="store_true", help="Uninstall macOS launchd 24/7 background service")
    args = parser.parse_args()

    daemon = AutonomousDaemon(poll_interval_hours=args.interval)

    if args.status:
        print_status()
    elif args.install_service:
        install_launchd_service()
    elif args.uninstall_service:
        uninstall_launchd_service()
    elif args.ingest_doi:
        daemon.run_cycle(specific_doi=args.ingest_doi)
    elif args.run_once:
        daemon.run_cycle()
    elif args.daemon:
        daemon.start_loop()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
