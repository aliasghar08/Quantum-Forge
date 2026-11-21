# Quantum Forge: Scripts & Automation Directory Guide

This directory houses all automation, background research pipelines, database seeding tools, dataset generators, and verification suites for Quantum Forge.

## Subdirectory Structure

### 1. `autonomous_research_pipeline/`
The 24/7 autonomous research and continual learning engine.
- `autonomous_pipeline_daemon.py`: Top-level supervisor daemon coordinating harvesting, ingestion, splitting, and MPS model training.
- `literature_harvester.py`: Asynchronously queries academic REST APIs (OpenAlex, CrossRef, EuropePMC, PubMed, Semantic Scholar) for newly published reaction coordinates and synthesis pathways.
- `scholarly_verifier.py`: Multi-tier authenticity validator verifying DOIs, author affiliations, journal impact factors, and retractions.
- `data_ingester.py`: Parses chemical files, verifies physical invariants (conservation of atoms, charge neutrality, spin multiplicity), and outputs `.extxyz` trajectories.
- `mps_trainer.py`: Continual PyTorch trainer leveraging Apple Silicon Metal Performance Shaders (MPS) for local GPU acceleration.
- `pharma_intelligence_model.py`: Multi-task GNN predicting Mechanism of Action (MoA), target species, and therapeutic disciplines.
- `train_pharma_model.py`: Training script for PharmaBioNet neural potential.
- `Dockerfile.harvester`: Container definition for Cloud Run / Cloud Build autonomous research nodes.

### 2. `firestore_seeding/`
High-throughput cloud streaming and maintenance tools for the 2.85M+ reaction library in Google Cloud Firestore.
- `firestore_bulk_reaction_seeder.py`: High-throughput threaded streamer with intelligent HTTP 429 backoff and auto-refreshing OAuth tokens.
- `firestore_fix_legacy_reactions.py`: Normalizes legacy Firestore documents to adhere to modern schema definitions.
- `firestore_upload_derived_jsonl.py`: Batch uploader for derived reaction JSONL files.
- `firestore_enrich_clinical_library.py`: Clinical metadata annotator for medical reactions.

### 3. `dataset_generators/`
Procedural reaction generation and client-side asset compilation.
- `generate_medical_reactions.py`: Combinatorial chemical reaction generator for MBBS & Pharm-D educational curricula.
- `export_medical_dart.py`: Compiles generated reaction trees into static, zero-latency Dart source files for Flutter.
- `export_pharmacopeia_dart.py`: Generates the official Quantum Forge Pharmacopeia Dart catalog.
- `enrich_all_templates_with_catalysts.py`: Augments reaction templates with organometallic and enzymatic catalysts.
- `generate_synthetic_db.py`: Creates synthetic test databases for local simulation.

### 4. `quality_audits/`
Benchmarking, calibration, and regression test suites.
- `audit_and_fix_template_dois.py`: DOI integrity audit and repair tool.
- `capture_cardio_audit.py`: Hemodynamic and electrophysiology waveform validation script.
- `capture_clinical_situations.py`: Generates automated clinical vignettes and audit trails.
- `capture_oscilloscope_realism.py`: High-speed oscilloscope waveform benchmark.
- `verify_library_and_history_tags.py`: Validates Firestore library schema tags against client history filters.
- `01_curate_transition1x.py` through `07_build_test_set.py`: Transition1x curation, conversion, validation, and MACE training benchmarks.

### 5. `service_management/`
Local development and microservice orchestration scripts.
- `start_backend.sh`: Launches local microservices with unified port bindings.
- `stop_backends.sh`: Gracefully shuts down active backend processes.
- `health_backends.sh`: Polls health endpoints across all 5 clinical and computational microservices.
- `build_all_backends.sh`: Builds Docker containers for all microservices.

### 6. `autonomous_trainer/` (Legacy Proxy Directory)
Maintained with backward-compatible wrappers to ensure legacy shell commands, launchd agents, and Docker builds continue operating without modification.
