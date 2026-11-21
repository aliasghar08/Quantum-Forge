# Seeder Backend: Autonomous Literature & Reaction Seeder Service

Cloud Run backend service orchestrating continuous chemical reaction seeding, literature data extraction, and Firestore library synchronization.

## Architectural Overview

* **Background Ingestion Engine**: Automatically parses chemical literature, resolves reaction mechanisms, generates MMFF94 3D Cartesian coordinates, and applies strict physical invariance gates (exact mass conservation, minimum steric distance $\ge 0.70\text{ \AA}$, activation barrier $0.02 \le E_a \le 4.0\text{ eV}$).
* **Multi-Discipline Pharmacopeia Sync**: Synchronizes human, veterinary, polymer, and everyday prescription medicines with Google Cloud Firestore (`/library`).
* **Service Entrypoints**:
  * `main.py`: FastAPI service handling seeder triggers and manual ingestion requests.
  * `Dockerfile`: Container image specification for Cloud Run deployment.
