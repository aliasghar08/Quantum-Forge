# Quantum Forge Autonomous Literature-Driven Training System

Quantum Forge features a fully autonomous, 24/7 background learning pipeline that eliminates dependency on Google Colab or manual model retraining. 

The system runs natively on your **Apple Silicon Mac (M1 Pro)** using **Metal Performance Shaders (MPS)** acceleration and macOS `launchd`. It only triggers training when newly published computational chemistry or transition state research appears on academic networks (OpenAlex, CrossRef, arXiv, Europe PMC, or user-provided DOIs).

---

## 🏗️ Architecture

```mermaid
graph TD
    A["Academic Networks<br/>(OpenAlex / CrossRef / DOIs)"] -->|Poll / Webhooks| B["Literature Harvester<br/>(scripts/autonomous_trainer/literature_harvester.py)"]
    B -->|Check Seen DOIs| C["SQLite Ledger<br/>(data/autonomous_training/literature_ledger.sqlite)"]
    C -->|New Research Found| D["Reaction Data Ingester<br/>(scripts/autonomous_trainer/data_ingester.py)"]
    D -->|Extract Coordinates & Physical Invariants| E["Zero-Leakage Trajectory Splitter"]
    E -->|Mix 200 Replay Frames| F["data/curated/t1x_hcno_stride50.extxyz<br/>(Anti-Forgetting Replay Buffer)"]
    F --> G["MPS Continual Trainer<br/>(scripts/autonomous_trainer/mps_trainer.py)"]
    G -->|Apple Silicon GPU (MPS) / nice +10| H["Fine-Tuned Checkpoints<br/>(models/continual_learning/)"]
    H -->|Auto-Promote Weights| I["tx1-fastapi-backend/models/ensemble_v2/<br/>(Live Model Serving)"]
```

## 🧬 Supported Reaction Archetypes & Element Coverage

Previously, the legacy Transition-1x dataset strictly restricted molecules to **HCNO** ($Z \in \{1, 6, 7, 8\}$) and simple isomerization. The autonomous system now actively discovers, ingests, and trains on 8 broad chemical reaction archetypes covering full medicinal and bio-organic chemistry:

| Reaction Archetype | Key Elements | Clinical / Chemical Significance |
| :--- | :--- | :--- |
| **Thiol-Disulfide Exchange** | S ($Z=16$), C, H, N, O | Cysteine chemistry, glutathione detoxification, penicillin $\beta$-lactam ring opening |
| **Phosphate Ester Hydrolysis** | P ($Z=15$), O, H, C | ATP hydrolysis to ADP, kinase phosphorylation, DNA/RNA backbone cleavage |
| **$S_N2$ Halogen Displacement** | Cl ($Z=17$), F ($Z=9$), Br ($Z=35$) | Alkyl halide substitutions, Walden inversion, fluorinated drug synthesis |
| **Pericyclic Cycloaddition** | C, H, N, O | Diels-Alder $[4+2]$ concerted cycloadditions, sigmatropic rearrangements |
| **Click Chemistry** | N, C, H | 1,3-Dipolar azide-alkyne cycloaddition, bioorthogonal ligation |
| **Radical Hydrogen Atom Transfer** | C, H, O, N | Free radical reactions, lipid peroxidation, enzymatic radical relays |
| **Enzyme / Peptide Hydrolysis** | C, N, O, H | Protease catalysis, amide bond cleavage, tetrahedral intermediate |
| **Aldol / Carbonyl Addition** | C, O, H | Carbon-carbon bond formation, enolate additions, carbohydrate chemistry |

### Isolated Atom Reference System ($E_0$)
The ingester carries calibrated atomic reference baselines across all supported elements:
* **H:** $-3.6672\text{ eV}$ | **B:** $-3.7601\text{ eV}$ | **C:** $-8.4056\text{ eV}$ | **N:** $-7.3601\text{ eV}$
* **O:** $-7.2846\text{ eV}$ | **F:** $-2.5932\text{ eV}$ | **Si:** $-4.4850\text{ eV}$ | **P:** $-5.4184\text{ eV}$
* **S:** $-10.1425\text{ eV}$ | **Cl:** $-1.7821\text{ eV}$ | **Br:** $-1.5302\text{ eV}$ | **I:** $-1.3204\text{ eV}$

1. **Zero-Leakage Trajectory Splitting:**
   - In reaction dynamics, adjacent frames along a minimum energy pathway ($R \rightarrow TS \rightarrow P$) are strongly correlated.
   - The ingester keeps entire reaction trajectories together in either train or validation—never splitting frames of the same reaction across both.
2. **Transition-1x Replay Buffer:**
   - Every training cycle mixes incoming research data with baseline Transition-1x frames to prevent catastrophic forgetting.
3. **Physical Invariant Verification:**
   - Rejects unphysical nuclear overlaps ($r_{ij} < 0.70$ Å) or infinite gradients before reaching the neural network.
4. **Low Priority Background Execution:**
   - Set to `nice +10` with background QoS so your daily Mac usage remains fast and responsive while it runs 24/7.

---

## 🛠️ CLI Operations & Commands

Activate the virtual environment:
```bash
source .venv/bin/activate
```

### 1. Check System & Ledger Status
Inspect tracked research papers, completed training cycles, and model checkpoints:
```bash
python scripts/autonomous_trainer/daemon.py --status
```

### 2. Manually Feed a Specific DOI
If you discover a paper or reaction dataset you want your model to learn from immediately:
```bash
python scripts/autonomous_trainer/daemon.py --ingest-doi 10.1038/s41524-023-01045-8
```

### 3. Run an Immediate Search & Train Cycle
Force an immediate poll of academic networks and training pass:
```bash
python scripts/autonomous_trainer/daemon.py --run-once
```

### 4. Background Service Management (`launchd`)
The service is registered in macOS `launchd` as `com.quantumforge.autotrainer` and runs in the background 24/7 (polling every 6 hours):

* **View live logs:**
  ```bash
  tail -f logs/autotrainer_stderr.log
  ```
* **Reinstall / Update service:**
  ```bash
  python scripts/autonomous_trainer/daemon.py --install-service
  ```
* **Uninstall service:**
  ```bash
  python scripts/autonomous_trainer/daemon.py --uninstall-service
  ```
