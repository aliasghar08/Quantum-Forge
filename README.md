# Quantum Forge 🧪⚛️

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Web-4285F4?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Web" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/PyTorch-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white" alt="PyTorch" />
  <img src="https://img.shields.io/badge/Tests-All%20Passing-brightgreen?style=for-the-badge" alt="Tests" />
</p>

**Quantum Forge** is an AI-assisted quantum chemistry, computational pharmacology, and interventional cardiology simulation workstation built **for the web** with Flutter. It gives researchers, pharmacologists, cardiologists, and students a single high-performance browser dashboard for building molecules, modelling transition states, predicting cardiorenal toxicology, and simulating full interventional cath-lab hemodynamics — with a two-way bridge to desktop **Avogadro 2**.

🌐 **Live Deployment**: [https://quantom-forge.web.app](https://quantom-forge.web.app)

## 🌐 Web-first platform

Quantum Forge targets modern web browsers. Leveraging WebGL, NGL molecular viewers, and Flutter Web, it delivers a heavy-duty computational-chemistry platform without requiring any desktop installation, on Windows, macOS, Linux, and ChromeOS.

## 🚀 Features

### 1. 3D interactive builder
* **Inverse raycasting** — click into the 3D void to place atoms; drag from an atom to grow a bond at the ideal covalent distance.
* **Element picker** over the full periodic table with CPK colours and covalent / van-der-Waals radii.
* **Force-field relaxation** while you draw (toggleable), plus orbit/zoom camera controls and three atom representations (ball & stick, space filling, wireframe).

### 2. Structure I/O — Avogadro 2 native
* **Reads** CJSON (Avogadro's native Chemical JSON), CML, XYZ, SDF and MOL.
* **Writes** CJSON, CML, SDF (V2000 connection table) and XYZ, with configurable coordinate precision and title lines.
* **Perceives bonds** from covalent radii with a valence-aware order refinement, so exported connection tables are chemically sensible rather than a flat atom list.
* **Multi-XYZ trajectories** — the whole NEB path exports as one file Avogadro animates image by image.

### 3. Transition-state modelling & animation

The animation reproduces **Avogadro 2's Animation Tool** (the *Player* tool) — see [`AVOGADRO_ANIMATION_PARITY.md`](quantum_forge/AVOGADRO_ANIMATION_PARITY.md) for the full control-by-control mapping:

* **WebGL playback through NGL**, using NGL's own impostor spheres and cylinder bonds with built-in ambient/diffuse/specular shading at `radiusScale 0.5 / aspectRatio 2.0`. Display types: Ball and Stick, Licorice, Van der Waals and Wireframe.
* **Orthographic camera** with 4× MSAA, antialiasing, display-matched pixel ratio and matched clip planes.
* **Two element palettes**, switchable from the header: Avogadro's own `element_color` table and the Jmol/CPK table.
* **Avogadro's Player panel** — `<` / `>` frame stepping, a 1-based `Frame: N/M` spin box, a frame slider, `Start:` / `End:` range controls, a `Dynamic bonding?` checkbox, a `Frame rate:` box in FPS (default 5), a `Play` ⇄ `Pause` button, and Avogadro's keyboard map (Space, ← →, Shift+← →, ↑ Start, ↓ End).
* **Discrete images, never interpolation.** An NEB image is a computed geometry; blending two of them would draw an unphysical structure.
* **Dynamic bonding** re-perceives every bond from the current frame's coordinates using Avogadro's rule (covalent radii plus a 0.45 Å tolerance, H–H and noble gases excluded).
* **Research readout alongside it**: frame, relative energy, absolute MACE energy, path progress, cycle duration, transition-state frame and live bond count.

### 4. 🎛️ Quantum Controls Engine (25 Researcher Parameters)

Quantum Forge features a comprehensive 25-parameter quantum control panel that directly dictates physical kinetics, solvent screening, catalyst pathways, and optimizer convergence both in-browser and across MLIP backends:

| Section | Parameter | Type / Range | Physical & Algorithmic Impact |
|---|---|---|---|
| **System** | **Temperature ($T$)** | 100 – 1000 K | Governs Eyring rate constants $k(T) = \frac{\kappa k_B T}{h} e^{-\Delta G^\ddagger / RT}$, dynamic Arrhenius kinetics slopes ($\ln k$ vs $1/T$), and thermal entropy contribution ($-T\Delta S^\ddagger$). |
| | **Pressure ($P$)** | 0.1 – 100 atm | Modulates gaseous $P\Delta V^\ddagger$ enthalpy activation corrections. |
| | **Implicit Solvent** | None, Water, DMSO, Acetonitrile, Ethanol, DCM, THF, Toluene | Evaluates electrostatic dielectric screening ($\varepsilon_r$ from 2.38 to 80.1), attenuating transition-state charge separation and stabilizing polar TS intermediates. |
| | **Charge ($q$)** | -3 to +3 | Configures net molecular charge for Hamiltonian matrix evaluation and open-shell radical states. |
| | **Spin Multiplicity ($2S+1$)** | Singlet, Doublet, Triplet, Quartet | Sets spin state, ensuring correct unrestricted Hartree-Fock or DFT spin density projection. |
| **Catalyst** | **Catalyst Active** | Boolean Toggle | Switches reaction mechanism between uncatalyzed and catalyzed pathways. |
| | **Literature Catalysts** | Pt/C, Pd/C, Ru/C, Zeolite H-ZSM-5, Grubbs-II, Wilkinson's, Organocatalysts, Acid/Base | Populates literature-validated catalytic barrier reductions ($\Delta E_{cat}$) and active-site profiles. |
| | **Barrier Reduction ($\Delta E_{cat}$)** | 0.0 – 50.0 kcal/mol | Directly reduces effective activation energy $E_a$, accelerating calculated Eyring reaction rates. |
| | **Turnover Frequency (TOF)** | $s^{-1}$ metric | Quantifies catalytic productivity and site efficiency. |
| **Theory & Optimizer**| **Theory Method** | Semi-empirical, MLIP, DFT, HF, Post-HF | Chooses Hamiltonian representation and potential energy surface evaluator. |
| | **Basis Set** | STO-3G, 6-31G*, def2-SVP, def2-TZVP | Controls Gaussian orbital expansion flexibility for electron density calculation. |
| | **SCF Convergence** | $10^{-4}$ to $10^{-8}$ Hartree | Sets density matrix and orbital energy convergence tolerance. |
| | **Optimizer Algorithm** | L-BFGS, FIRE, QuickMin, Steepest Descent | Directs coordinate relaxation trajectory along the potential energy surface. |
| | **Max Steps** | 10 – 500 | Prevents infinite optimization loops in shallow potential wells. |
| | **Force Convergence ($f_{max}$)** | 0.001 – 0.05 eV/Å | Halts geometric relaxation when maximum atomic force falls below threshold. |
| **Path & Analysis** | **NEB Images** | 5 – 101 frames | Sets nudged elastic band discretization resolution; drives both backend solver frames and in-browser neural trajectory interpolation. |
| | **Spring Constant ($k_{spring}$)** | 0.01 – 1.0 eV/Å² | Controls inter-image spring stiffness along the minimum energy path (MEP). |
| | **TS Search Algorithm** | CI-NEB, Dimer Method, Sella, Berny TS | Selects saddle-point finding routine for rigorous transition-state localization. |
| | **ZPE Correction** | Toggle + Scale Factor (0.8 – 1.05) | Computes Zero-Point Vibrational Energy offset ($\sum \frac{1}{2}h\nu_i$) to convert electronic $\Delta E^\ddagger$ to enthalpy $\Delta H_0^\ddagger$. |
| | **Frequency / IR Analysis** | Toggle | Diagonalizes mass-weighted Hessian matrix to verify exactly one imaginary frequency ($\nu^\ddagger < 0$) and produce simulated IR stick spectra. |

### 5. 💊 Clinical Pharmacopeia & Veterinary (DVM) Medicine Suite

Quantum Forge includes curated, literature-validated synthesis pathways and transition states for healthcare, pharmacology, and veterinary science:
* **Human Clinical Medicine Benchmarks (MBBS & Pharm-D)**:
  * 25+ essential therapeutics with complete reaction coordinates: **Paracetamol** (Acetaminophen synthesis via $p$-aminophenol acylation), **Aspirin** (Salicylic acid esterification), **Ibuprofen** (Darzens condensation/Friedel-Crafts), **Amoxicillin** ($\beta$-lactam acylation), **Metformin** (Biguanide condensation), **Omeprazole** (Proton-pump inhibitor sulfide oxidation), **Ciprofloxacin** (Fluoroquinolone nucleophilic aromatic substitution), **Atorvastatin** (Statin HMG-CoA core construction), **Losartan** (Tetrazole ring formation), and **Salbutamol** (Albuterol $\beta_2$-agonist synthesis).
* **Veterinary Medicine Benchmarks (DVM)**:
  * 10+ essential veterinary therapeutics: **Ivermectin** (Antiparasitic macrolide semi-synthesis), **Flunixin Meglumine** (Equine NSAID cycloaddition), **Carprofen** (Canine anti-inflammatory carbazole coupling), **Enrofloxacin** (Veterinary fluoroquinolone ethylation), **Phenylbutazone** (Equine pyrazolidinedione condensation), **Meloxicam** (Enolic acid NSAID synthesis), and **Marbofloxacin**.
* **Dynamic Medical Dossier Card**:
  * Automatically detects medicinal compounds using reaction metadata and clinical chemical templates.
  * Dynamically renders Mechanism of Action (MoA), clinical indications, target species (Canine, Feline, Equine, Bovine, Human), routes of administration, dosage forms, and **WHO Model List of Essential Medicines** qualification badges.
  * Displays direct clickable **DOI Literature Citations** linking to peer-reviewed synthesis papers.

### 6. 🧪 Polymer Chemistry & Expanded Cloud Library
* **Industrial Polymer Synthesis**: Complete reaction coordinates and intermediate transition states for commodity and engineering polymers:
  * Polyethylene Terephthalate (PET condensation)
  * Nylon 6,6 (Hexamethylenediamine + Adipoyl chloride polyamidation)
  * Polystyrene (Free-radical chain-growth polymerization)
  * Polylactic Acid (PLA ring-opening polymerization)
  * Polyurethane (Diisocyanate polyaddition)
  * Bakelite (Phenol-formaldehyde crosslinking)
  * Polymethyl Methacrylate (PMMA)
  * Polytetrafluoroethylene (PTFE)
* **Cloud Reaction Library (200,000+ Combinatorial & Literature Reactions)**:
  * Multi-dimensional filtering by reaction category (Addition, Substitution, Elimination, Rearrangement, Oxidation, Reduction, Organometallic, Coupling, Cycloaddition, Polymer, Electrochemistry, Biomimetic, Photochemical, Acid-Base, Radical).
  * Educational Tier filtering: High School, Undergraduate, Graduate, and Advanced Research.
  * Direct DOI hyperlinks to peer-reviewed journal articles.
  * **Headless YouTube Educational Scraper**: Scrapes relevant lecture videos and tutorials directly in-browser using `youtube_explode_dart` without external API quotas or GCP billing.

### 7. 🧬 In-Browser Neural Trajectory Compressor
* **Transformer Reaction Compressor** (`TransformerReactionCompressor`):
  * Utilizes geometric multi-head self-attention and collision-free frame decoding directly in Dart/Web.
  * Dynamically resamples and decompresses NEB trajectories to exactly match the researcher's configured `neb_images` (from 5 to 101 frames).
  * Implements dielectric solvent electrostatic screening ($\varepsilon_r$) and thermal activation entropy modulation during frame decoding.
  * Enforces steric clash avoidance with minimum covalent radii constraints, guaranteeing physically valid molecular geometries across every intermediate frame.

### 8. Reaction dashboards
* Energy profile (ΔE‡, ΔH‡), Arrhenius kinetics, simulated IR sticks.
* Live thermodynamic cards: Gibbs energy, enthalpy, entropy, rate constant, ZPE,
  dipole, HOMO–LUMO gap, polarisability, RMS gradient.

### 9. Hybrid ML/MM Molecular Dynamics
* **Complete Peptide System**: Natively handles both `.pdb` and `.xyz` uploads. Automatically solvates, neutralizes, and adds missing hydrogens using OpenMM `Modeller`.
* **Dynamic MLIP Masking**: Custom PyTorch TorchScript masking restricts the MLIP evaluation solely to the peptide atoms, letting AMBER19 handle the massive solvent box.
* **UI Integration**: Control simulation length dynamically from the 3D builder and launch GPU-accelerated jobs directly from the browser.

### 10. ❤️ CardioCath 3D: Interventional Cardiology, Myocardial Biomechanics & Hospital ICU Telemetry

`CardioCath 3D Lab` is a cutting-edge computational cardiology, structural heart, and bedside ICU/CCU electrophysiology workstation integrated directly into Quantum Forge:

* **3D Anatomical Heart Viewport**:
  * Real-time beating WebGL 3D myocardial geometry synchronized with Wiggers diagrams and electro-mechanical phase locking.
  * Interactive layer toggles: **Gross Anatomy**, **Coronary Perfusion**, **Cardiac Conduction System**, and **Blood Flow Hemodynamics**.
* **Coronary Angiography & Fluoroscopy C-Arm Gantry Digital Twin**:
  * Realistic X-ray fluoroscopy shader with pulsed exposure, inverse-square scatter, and radiopaque catheter tracking.
  * Synchronized dual-axis C-Arm gantry supporting standard clinical projections (**LAO/RAO Cranial/Caudal**, Spider view).
  * Real-time contrast dye opacification, washout kinetics, and myocardial blush grading (MBG 0–3).
* **5-Channel Hospital Bedside Oscilloscope (Philips IntelliVue / GE CARESCAPE Parity)**:
  * **Channel 1 & 2 (Dual Simultaneous ECG Leads — Lead II + Precordial V1)**: Phosphor-green CRT traces with persistence decay, sweep erase bar, 1 mV calibration pulse, and adjustable sweep speeds (25 vs 50 mm/s) & gains (5, 10, 20 mm/mV).
  * **Channel 3 (Invasive Arterial Blood Pressure — $ABP$ $P_a$ & $P_d$)**: Arterial pressure waveform with dicrotic notch, catheter damping, and dual distal $P_d$ trace when PressureWire X is engaged.
  * **Channel 4 (Photoplethysmogram $SpO_2$ Pleth)**: Real photoplethysmogram with pulse transit delay, dicrotic reflection, and low-perfusion collapse during code blue rhythms.
  * **Channel 5 (Alveolar Capnography $EtCO_2$)**: Real-time Phase I–IV capnogram ($35\text{–}45\text{ mmHg}$) dropping to $< 10\text{ mmHg}$ during cardiac arrest and surging at ROSC.
  * **14 Arrhythmia & Conduction Rhythms**: NSR, Sinus Brady/Tachy, Atrial Fibrillation with fibrillatory $f$-waves, Atrial Flutter (sawtooth $F$-waves), SVT (AVNRT), 1st-Degree AV Block ($PR > 200\text{ ms}$), 2nd-Degree Mobitz I (Wenckebach) & Mobitz II, 3rd-Degree Complete Heart Block, Monomorphic VT, Torsades de Pointes, Ventricular Fibrillation (VF), and Asystole.
  * **Resuscitation Suite**: 200J Biphasic Defibrillator (ROSC recovery) and Transcutaneous Pacing (TCP, 70 bpm ventricular capture).
  * **Electronic Measurement Calipers**: Freeze-frame measurement overlay with interactive drag calipers reporting exact $\Delta t$ (ms) and instantaneous heart rates (bpm).
  * **Authentic Physiological Signal Realism**: Deterministic $0.22\text{ Hz}$ respiratory baseline wander, skeletal muscle EMG & electrode micro-noise, beat-to-beat Respiratory Sinus Arrhythmia (HRV) amplitude modulation ($\pm 6\%$), arterial line pulse-pressure swing ($-4.5\text{ mmHg}$), fluid catheter resonance ringing, and $60\text{ Hz}$ AC mains hum interference.
  * **Hospital Pink Thermal Paper Mode**: Interactive toggle transforming the display into authentic hospital $1\text{ mm} / 5\text{ mm}$ pink grid paper with deep charcoal/slate medical ink needles.
* **🎓 MBBS, Pharm-D, USMLE & NEET-PG Clinical Ward Preparation Suite**:
  * **💉 Live "Administer IV Drug" Ward Simulator**:
    * Interactive multi-medication infusion pump drawer integrated directly into the 5-Channel Hospital Monitor.
    * Real-time pharmacological hemodynamic & electrophysiological responses:
      * **Adenosine (6 mg rapid IV push)**: Induces transient 2.5-second AV nodal block / ventricular pause, breaking SVT back to Normal Sinus Rhythm (76 bpm).
      * **Atropine (1 mg IV push)**: M2 muscarinic antagonist blocking vagal parasympathetic tone, accelerating Sinus Bradycardia (45 $\rightarrow$ 85 bpm).
      * **Norepinephrine (Levophed 4 mcg/min)**: Potent $\alpha_1$-vasoconstriction and $\beta_1$-inotropy, elevating invasive blood pressure from shock to 125/82 mmHg (MAP 96 mmHg).
      * **Nitroglycerin (10 mcg/min / SL)**: Potent venodilator reducing preload, blunting ischemic ST elevation; triggers critical alert and severe hypotension (72/42 mmHg, MAP 52 mmHg) if given in RV Infarct / Inferior STEMI.
      * **Amiodarone ($hERG$ Challenge)**: Class III $I_{Kr}$ potassium channel blockade prolonging $QT_c > 540\text{ ms}$, triggering Polymorphic VT / Torsades de Pointes.
      * **Magnesium Sulfate (2 g IV push)**: Suppresses Early Afterdepolarizations (EADs) and inward $Ca^{2+}$ flux, terminating Torsades de Pointes back to Normal Sinus Rhythm (80 bpm).
  * **🎯 "Blind Diagnosis" ECG & Auscultation Board Trainers**:
    * **Blind ECG Rhythm Exam**: Masks rhythm name, presenting a 4-choice interactive quiz with caliper measurement hints, instant board-style rationales, and live score tracking.
    * **Blind Murmur Auscultation Trainer**: Masks murmur labels in the Phonocardiography (PCG) & Echo Doppler workstation, challenging students to deduce valvular pathologies (Aortic Stenosis, Mitral Regurgitation, HOCM, Mitral Stenosis) using bedside dynamic maneuvers (Valsalva, Squatting, Sustained Handgrip).
  * **📚 21-Case Embedded Medical Board QBank & SuperMemo SM-2 Spaced Repetition**:
    * 21 high-yield two-step clinical vignettes across **Cardiology**, **Pharmacology & Toxicology**, **Resuscitation & ACLS**, and **Valvular & Structural Heart Disease**.
    * SuperMemo SM-2 spaced repetition algorithm with interval, ease factor, repetition count, and next-review scheduling persisted in `AppStorage`.
    * **"🚀 Launch 3D Simulation"**: 1-click sync loading patient anatomy, fluoroscopy projections, hemodynamics, and arrhythmia parameters directly into the CardioCath 3D digital twin.
  * **📋 1-Click "Ward Rounds & Anki" Visual Study Sheet Exporter**:
    * High-yield 1-page visual dossier generator with 1-tap **"📋 Copy Anki Flashcard"** (Anki Cloze & Q/A formats) and **"📄 Download Ward Study Sheet"** (Markdown).
    * Integrated seamlessly into both CardioCath 3D Lab and Clinical Reaction Dossiers.
  * **🏷️ Curriculum & Medical Subfield Classification Tags**:
    * Systematic dual tagging across all template cards in both Reaction Library and History systems, explicitly labeling educational tracks (**MBBS**, **Pharm-D**, **USMLE**) and clinical subfields (**Cardiology**, **Neurology**, **Oncology**, **Endocrinology**, **Infectious Disease**).
* **4 Next-Generation PyTorch Computational Cardiology Engines (`cardiocath-backend/`)**:
  * **`CardioFNO-3D`**: Fourier Neural Operator trained on Apple Silicon MPS computing 3D myocardial strain tensors (Global Longitudinal Strain `GLS %`, radial thickening, circumferential shortening) and live 17-Segment AHA Polar Bullseye Maps (apical sparing, septal flash, transmural infarcts).
  * **`CardioRotor-3D`**: 3D Reaction-Diffusion Monodomain tissue solver mapping electrical wavefront curvature, re-entrant circuits, spiral-wave phase singularities (rotors), and endocardial scar homogenization ablation.
  * **3D Structural Heart Morphometry & Valve-to-Coronary (VTC) Distance**: Interactive aortic root/annulus analyzer for TAVR / Valve-in-Valve coronary obstruction risk assessment ($< 4\text{ mm}$ high-risk alert), BASILICA leaflet laceration simulation, and Left Atrial Appendage Occluder (LAAO) sizing.
  * **Invasive Right-Heart Catheterization (Swan-Ganz) & CPET**: Catheter pullback pressure waveforms ($RA \rightarrow RV \rightarrow PA \rightarrow PCWP$ wedge pressure), Fick cardiac output, and cardiopulmonary exercise testing ($\dot{V}O_2$, $\dot{V}CO_2$, $\dot{V}_E/\dot{V}CO_2$ slope).
  * **CardioNephroGNN Screener**: 5-member deep learning ensemble predicting dual cardiotoxicity ($hERG$ $IC_{50}$) and nephrotoxicity with epistemic uncertainty and ChEMBL cross-references.
  * **CardioElectrophys-Net & CardioPINN**: CiPA action potential solver (IKr, INa, ICaL) and physics-informed neural network for non-invasive parameter inversion.
* **SaMD 7-Pillar Legal & Liability Shield**:
  * Prominent statutory disclaimer banner ("Educational Simulation Only — Not for Clinical Diagnosis or Patient Care") and comprehensive compliance documentation dialog.

### 11. ⚖️ Stoichiometric LST Balancing & Reaction Robustness
* **Dynamic Coordinate Matrix Balancing**: The FastAPI reaction pathway engine in `tx1-fastapi-backend/` dynamically balances leaving groups and spectator species (`auto_balance=True`), borrowing coordinate positions for missing atoms and pruning surplus byproducts.
* **Literature Template Harmonization**: All 35+ foundational pharmaceutical templates (including Paracetamol, Aspirin, Glimepiride, Captopril, and Atorvastatin) feature verified 1:1 atom-for-atom stoichiometry, preventing unphysical reaction path aborts.

### 12. Scientific theming
Seven presets, each grounded in a real convention rather than a colour preference:

| Preset | Family | Idea |
| --- | --- | --- |
| Dark Matter | Deep field | Low-glare default for long optimisation runs |
| Quantum Blue | Orbital | Cherenkov blue, metallic renderer |
| Neon Synth | Spectroscopy | Laser pink + cyan on violet, translucent atoms |
| Electron Cloud | Density | Teal isosurface palette, high VDW opacity |
| Spectroscopy | Spectroscopy | Low-glare slate with warm IR / violet UV-Vis accents |
| Scientific Light | Publication | Print-quality light theme for figures and projectors |
| Journal Mono | Publication | Greyscale-first, Okabe–Ito colour-blind-safe plots |

Themes persist across sessions; <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>T</kbd> cycles them.

### 13. Settings that actually apply
*Settings* is a real screen (drawer gear icon, or the app-bar gear) with five tabs —
Appearance, Editor, Export, Avogadro, Compute. Every control writes through to
storage immediately and takes effect without a restart:

* **Appearance** — theme presets, compact mode, reduce motion, tooltips.
* **Editor** — default element, auto-optimise, atom representation, bond drawing,
  hydrogen visibility, bond-perception tolerance, auto-save interval.
* **Export** — default format, coordinate precision, title line, plus a live preview
  of what those settings actually produce.
* **Avogadro** — bridge endpoint (hosted / localhost / custom), deep-link import
  toggles, and the per-platform plugin install path.
* **Compute** — temperature, step count, NEB images, convergence, and the analysis
  switches, mirroring the Quantum Controls panel.

### 14. Avogadro 2 bridge
Two directions, because Avogadro 2 has no URL-open hook:

* **Avogadro → web.** The bundled plugin (`avogadro_plugin/`) sends the open molecule
  as CJSON through a deep link; the editor opens with it pre-loaded (or a banner
  offers to, if auto-load is off). The payload is stripped from the address bar
  afterwards so a refresh does not re-import it.
* **Web → Avogadro.** *Export* writes CJSON/CML/SDF/XYZ files, *Export trajectory*
  writes the multi-XYZ path, and *Export bundle (.zip)* packages trajectory, final
  structure (XYZ + CJSON) and an energy manifest. See
  [`avogadro_plugin/README.md`](quantum_forge/avogadro_plugin/README.md).

### 15. Accounts
Firebase Authentication with profile and email shown in the drawer.

## 🛠️ Stack

* **Frontend**: Flutter (web) · Dart · `dart:js_interop` for browser APIs
* **State**: `provider` (`ChangeNotifier` + `ValueNotifier`)
* **Backend as a service**: Firebase Auth · Cloud Firestore · Firebase Hosting
* **Chemistry**: custom format writers/parsers; Avogadro 2 via a Python plugin
* **UI**: Material 3, `flutter_staggered_animations`, hand-written `CustomPainter` charts

## ⚙️ Running it

```bash
git clone https://github.com/aliasghar08/Quantum-Forge.git
cd Quantum-Forge/quantum_forge
flutter pub get
flutter run -d chrome
```

Quality gates:

```bash
flutter analyze   # must be clean (0 issues)
flutter test      # 387 passing tests
```

### Pointing the plugin at a local build

```bash
export QUANTUM_FORGE_URL=http://localhost:8080   # or $env: on PowerShell
```

The same value can be set in *Settings ▸ Avogadro ▸ Bridge endpoint*.

## 🔬 MLIP & Quantum Compute Backends

Quantum Forge integrates multiple Machine Learning Interatomic Potentials (MLIP) and semi-empirical quantum chemistry methods through modular, stateless FastAPI microservices:

| Backend | Port | Model / Architecture | Default Device | Environment |
|---|---|---|---|---|
| `mace-backend` | **8001** | **MACE-MP-0** (*Batatia et al., NeurIPS 2022*) | `cpu` (safe for float64 on Apple Silicon) | Shared `.venv` |
| `chgnet-backend` | **8002** | **CHGNet** (*Deng et al., Nature MI 2023*) | `mps` / `cuda` | Shared `.venv` |
| `ani2x-backend` | **8003** | **ANI-2x** (*Devereux et al., JCTC 2020*) | `mps` / `cuda` | Shared `.venv` |
| `gfn2-xtb-backend` | **8004** | **GFN2-xTB** (*Bannwarth et al., JCTC 2019*) | CPU | Conda `xtb-env` |
| `tx1-fastapi-backend` | **8005** | **Transition1x GNN** (*Schreiner et al., Sci. Data 2022*) | CPU | Shared `.venv` |
| `cardiocath-backend` | **8006** | **CardioFNO-3D & CardioNephroGNN** (*PyTorch Biomechanics & Windkessel*) | `mps` / `cpu` | Shared `.venv` |

---

### Local Development Workflow

Starting, stopping, and inspecting backends is managed via helper scripts in `scripts/`:

#### 1. Start a backend
Run each backend in its own terminal tab:
```bash
./scripts/start-backend.sh mace-backend
```
What `start-backend.sh` does automatically:
- Validates that the directory exists and maps it to its designated port.
- Verifies the port is not in use (`lsof -ti:<port>`); exits cleanly with conflict details if occupied without killing it.
- Activates the proper Python environment (`xtb-env` conda environment for `gfn2-xtb-backend`, or repo root `.venv` for all other backends).
- Automatically sets `PYTORCH_ENABLE_MPS_FALLBACK=1`.
- Executes `python -m uvicorn main:app --host 0.0.0.0 --port <port>` without `--reload` (preventing supervisor processes that re-lock ports upon Ctrl+C).
- Traps `SIGINT`/`SIGTERM` to cleanly terminate and release the port.

#### 2. Check health across all backends
In another terminal, poll all 5 services simultaneously:
```bash
./scripts/health-backends.sh
```
Example output:
```
mace-backend        (8001): ok       — MACE-MP-0 ready (device: cpu)
chgnet-backend      (8002): ok       — CHGNet universal potential ready (device: mps)
ani2x-backend       (8003): ok       — ANI-2x ready (device: mps)
gfn2-xtb-backend    (8004): ok       — GFN2-xTB calculator ready
tx1-fastapi-backend (8005): ok       — Transition1x GNN ready
```
For any backend not running:
```
<backend> (<port>): not running
```

#### 3. Stop backends
```bash
# Stop a specific backend
./scripts/stop-backends.sh mace-backend

# Stop all backend services across all 5 ports
./scripts/stop-backends.sh --all
```

#### 4. How the Flutter App Routes Requests
In `quantum_forge/lib/state/settings_provider.dart`, the app derives the target endpoint dynamically through `settings.effectiveBackendUrl`:
- `mlipModel = 'tx1-fastapi'` → `http://localhost:8005`
- `mlipModel = 'MACE-MP-0'` or `'MACE-OFF23'` → `http://localhost:8001`
- `mlipModel = 'CHGNet'` → `http://localhost:8002`
- `mlipModel = 'ANI-2x'` → `http://localhost:8003`
- `mlipModel = 'GFN2-xTB'` → `http://localhost:8004`

If an explicit `backendUrl` override is provided in Settings, that override is preferred; otherwise it defaults seamlessly to the local port for the selected model.

#### 5. Docker builds with pre-baked weights
For cloud deployment (e.g. Render free tier), every backend includes a multi-stage Dockerfile that pre-downloads and bakes its model weights during image build:
```bash
# Build and verify a single container image
./scripts/build-backend.sh mace-backend

# Build and verify all 5 backend images sequentially
./scripts/build-all-backends.sh
```
The script builds the image, starts it in the background, waits for `/health` to report `{"status":"ok"}`, checks the container stdout for `[MLIP] <Model> loaded from <source>`, and stops the container cleanly.

---


### Apple Silicon (MPS) Notes

- **Float64 on MPS**: Apple Silicon Metal Performance Shaders (MPS) framework does not support 64-bit floating point (`float64`) tensors. MACE foundation models deserialize and run internal operations with double precision.
- **Automatic Fallback**: All PyTorch backends include `os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")` which tells PyTorch to evaluate unsupported MPS kernels on CPU.
- **CPU Fallback (`MACE_DEVICE=cpu`)**: While MPS acceleration is faster for short predictions, long NEB trajectory optimizations can be memory-intensive. You can force CPU execution at any time:
  ```bash
  MACE_DEVICE=cpu ./scripts/start-backend.sh mace-backend
  ```

---

### Troubleshooting

- **`No module named uvicorn`**:
  Your active shell is using system Python (`/usr/bin/python3` or Xcode's toolchain) instead of the virtualenv. Activate the venv with `source .venv/bin/activate` or use `./scripts/start-backend.sh <backend>`.
- **`Address already in use`**:
  A previous uvicorn reloader process or crashed worker is still holding the port. Run:
  ```bash
  ./scripts/stop-backends.sh <backend>
  ```
- **`Model unavailable: ...` in `/health`**:
  The checkpoint could not be downloaded or initialized. Ensure internet access is available for Hugging Face or set your token:
  ```bash
  export HF_TOKEN="your_huggingface_token"
  ```
- **`Cannot convert a MPS Tensor to float64 dtype`**:
  Force CPU execution for MACE:
  ```bash
  MACE_DEVICE=cpu ./scripts/start-backend.sh mace-backend
  ```

---

## 📁 Layout

```
Quantum-Forge/
├── quantum_forge/        # Flutter Web App (Frontend)
│   ├── lib/              # Core application logic, features, and UI
│   │   ├── core/         # Core services, themes, and Avogadro bridges
│   │   └── features/     # Feature modules (reaction_runner, reaction_library, etc.)
│   ├── assets/           # Chemical assets, bundled 3D reactions
│   ├── avogadro_plugin/  # Python plugin to bridge with Avogadro 2
│   └── test/             # Unit and widget tests
├── scripts/              # Shared development automation scripts
│   ├── start-backend.sh  # Safe backend runner (venv check, port check, MPS fallback)
│   ├── stop-backends.sh  # Clean process termination utility
│   ├── health-backends.sh # Multi-backend health polling script
│   ├── build-backend.sh  # Docker build and container health verification
│   └── build-all-backends.sh # Sequential build & verification of all 5 backends

├── mace-backend/         # MACE-MP-0 Foundation Potential service (Port 8001)
├── chgnet-backend/       # CHGNet Universal Potential service (Port 8002)
├── ani2x-backend/        # ANI-2x Deep Learning Potential service (Port 8003)
├── gfn2-xtb-backend/     # GFN2-xTB Semi-Empirical QM service (Port 8004)
├── tx1-fastapi-backend/  # Transition1x GNN compute service (Port 8005)
├── cardiocath-backend/   # Computational Cardiology, FNO-3D & Swan-Ganz service (Port 8006)
└── .github/              # CI/CD Workflows for automated analysis and deployment
```

## 👤 Author

Developed by **Ali Asghar**
