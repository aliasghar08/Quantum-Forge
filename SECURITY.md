# Security Policy & Vulnerability Disclosure

**Platform:** Quantum Forge™ (Quantom Forge)  
**Author & Maintainer:** Ali Asghar  
**Official Security Contact:** [aliasgharinnocent@yahoo.com](mailto:aliasgharinnocent@yahoo.com)  
**Production Domains:** [https://quantumforgeapp.com](https://quantumforgeapp.com) · [https://quantom-forge.web.app](https://quantom-forge.web.app)  

---

## 1. Reporting a Vulnerability

We take the security, integrity, and safety of Quantum Forge very seriously. If you discover a security vulnerability, sensitive data exposure, API authentication issue, or algorithmic safety breach, **please DO NOT create a public GitHub issue**. Instead, report it directly to our security team.

### Submission Instructions:
Send an encrypted or private email to:
👉 **[aliasgharinnocent@yahoo.com](mailto:aliasgharinnocent@yahoo.com)**

Please include:
* A detailed description of the vulnerability.
* Specific steps to reproduce the issue (including sample requests, payloads, or URLs).
* Affected components (e.g., Flutter Web frontend, Cloud Run microservices, Firestore security rules, AI model weights, or chemical filtering pipelines).
* Potential security, computational, or privacy impact.
* (Optional) Any suggested remediation or patch.

### Security Response Commitments (SLA):
* **Initial Acknowledgment:** Within **24 hours**.
* **Triage & Severity Classification:** Within **48 hours**.
* **Remediation & Patch Deployment:** Critical vulnerabilities are addressed via immediate Cloud Run and Firebase releases within **72 hours**.
* **Public Advisory:** A coordinated security advisory will be published upon full resolution, crediting the researcher.

---

## 2. Chemical Safety & Dual-Use Chemical Defense Screening

Quantum Forge models atomic transition states, molecular potential energy surfaces, and organic chemical synthesis. To prevent the misuse of computational chemistry capabilities:

1. **Automated Threat Screening (`safety_filter.py`)**: All chemical inputs (SMILES, InChI, CAS numbers, and IUPAC names) passed to autonomous harvesting, seeding, or cloud inference pipelines are screened against:
   * The **Chemical Weapons Convention (CWC)** Schedule 1, 2, and 3 lists (including nerve agents, vesicants, and dual-use synthetic precursors).
   * **DEA Controlled Substances** Schedules I and II.
   * Highly lethal toxins, biological agents, and explosive precursors (G-series, V-series, Novichok agents, ricin, saxitoxin).
2. **Immediate Pipeline Blacklisting**: Any compound flagged by the automated safety filter is immediately blocked, logged with timestamped security telemetry, and dropped from processing before force-field relaxation, MMFF94 conformer generation, or Firestore publication.
3. **Fact-Only Ingestion**: The autonomous research pipeline stores only uncopyrightable, verified physical facts (activation energies $E_a$, literature DOIs, PMIDs, PDB IDs, and standard FDA pharmacokinetic properties). It never generates or distributes dangerous synthesis procedures or actionable recipes for harmful substances.

---

## 3. Software as a Medical Device (SaMD) Security & Safety Boundary

Quantum Forge implements a strict **7-Pillar SaMD Educational Shield**:
* The platform is intended exclusively for **theoretical computational research, academic education, and physiological simulation**.
* It **does not** provide medical advice, diagnosis, treatment, surgical guidance, or patient-specific prescriptions.
* No clinical decision-making or therapy administration may rely on Quantum Forge simulations.
* Banners and warning dialogs are permanently embedded and cannot be disabled via client-side manipulation.

---

## 4. Cloud Infrastructure & Authentication Security

* **Google Cloud Platform (GCP)**: All microservices run in isolated, least-privilege Google Cloud Run containers in `us-central1` using dedicated IAM service accounts (`227207155336-compute@developer.gserviceaccount.com`).
* **Firestore Security Rules**: The Cloud Firestore `/library` collection enforces read-only access for anonymous clients and requires authenticated service account bearer tokens for ingestion writes.
* **Secret Management**: API keys, service credentials, and private tokens are managed through Google Cloud Secret Manager and environment variables; they are never committed to version control.
* **HTTPS & HSTS**: All web endpoints enforce HTTP Strict Transport Security (`max-age=31556926; includeSubDomains; preload`) and TLS 1.3 encryption.

---

## 5. Supported Versions

| Version | Status | Security Support |
|---|---|---|
| **Quantum Forge 2.x (Latest Web/Cloud)** | Supported | ✅ Full 24/7 Security & Vulnerability Updates |
| Quantum Forge 1.x | Deprecated | ⚠️ Critical Fixes Only |
| Pre-release / Experimental Branches | Unsupported | ❌ None (Use `main` branch only) |
