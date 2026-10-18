# Quantum Forge 🧪⚛️

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Web-4285F4?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Web" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Tests-387%20Passing-brightgreen?style=for-the-badge" alt="Tests" />
</p>

**Quantum Forge** is an advanced, AI-powered quantum chemistry optimization and visualization platform built **exclusively for the Web** using Flutter. Designed for computational chemists, pharmacologists, researchers, and students, it provides an intuitive, high-performance web dashboard for visualizing molecular structures, modeling transition states, and calculating complex thermodynamic and kinetic properties directly in the browser.

🌐 **Live Deployment**: [https://quantom-forge.web.app](https://quantom-forge.web.app)

---

## 🌐 Web-First Architecture

Quantum Forge is optimized specifically for modern web browsers. Leveraging WebGL, NGL molecular viewers, and Flutter Web, it delivers a heavy-duty computational chemistry suite without requiring desktop installations. Whether on Windows, macOS, Linux, or ChromeOS, access the full suite of simulation tools from anywhere.

---

## 🚀 Comprehensive Feature List

### 1. 3D Interactive Physics Engine & Molecular Builder
* **Inverse Raycasting**: Custom 3D drawing engine built from scratch. Click into empty 3D space to place atoms, or drag from an existing atom to sprout bonds at ideal covalent distances.
* **Periodic Table Picker**: Comprehensive CPK color palette, covalent and van-der-Waals radii for all elements.
* **Real-time Force-Field Relaxation**: Interactive geometry relaxation while drawing with customizable bond perception tolerances.
* **Camera Controls**: Orbiting, panning, and zooming with support for touch, trackpad, and mouse interactions.
* **Three Atom Representations**: Ball & Stick, Space Filling (VDW), and Wireframe.

### 2. Deep File Format Parsing & Avogadro 2 Interoperability
* **Multi-Format Parsing**: Natively parses `.cjson`, `.mol`, `.sdf`, `.cml`, and `.xyz` files directly in the browser without server roundtrips.
* **Avogadro 2 Native**: Full bi-directional CJSON support. Load structures exported directly from desktop Avogadro 2 or pipe open structures directly via the bundled Python plugin.
* **Intelligent Bond Perception**: Valence-aware bond order perception refinement prevents flat atom-list representations and exports chemically sound connection tables.

### 3. Transition State (TS) Modeling & Avogadro Player Parity
Faithful reproduction of Avogadro 2's Animation Tool (`playertool.cpp`):
* **Avogadro Player Panel**: `<` / `>` stepping, 1-based `Frame: N/M` spin box, frame slider, `Start:` / `End:` range controls, `Dynamic bonding?` checkbox, FPS control (default 5 FPS), `Play` ⇄ `Pause`, and Avogadro's complete keyboard map (Space, ← →, Shift+← →, ↑ Start, ↓ End).
* **WebGL Rendering via NGL**: Impostor spheres and cylinder bonds at `radiusScale 0.5 / aspectRatio 2.0` under an orthographic camera with 4× MSAA and display-matched pixel ratios.
* **Element Palettes**: Switch seamlessly between Avogadro's native `element_color` table and standard Jmol/CPK palettes.
* **Discrete Computed Frames**: Strictly displays genuine NEB/MLIP computed intermediate geometries without unphysical geometric blending.
* **Dynamic Bonding**: Re-evaluates covalent bonds per frame (+0.45 Å tolerance, H-H and noble gases excluded) to dynamically visualize bond formation and cleavage during reaction pathways.

### 4. 🎛️ Quantum Controls Engine (25 Researcher Parameters)
Directly control physical kinetics, solvent screening, catalyst pathways, and optimizer convergence both in-browser and across MLIP backends:

* **System Configuration**:
  * **Temperature ($T$)** (100 – 1000 K): Dynamically updates Eyring rate constants $k(T) = \frac{\kappa k_B T}{h} e^{-\Delta G^\ddagger / RT}$, Arrhenius slopes ($\ln k$ vs $1/T$), and thermal entropy contributions ($-T\Delta S^\ddagger$).
  * **Pressure ($P$)** (0.1 – 100 atm): Adjusts $P\Delta V^\ddagger$ enthalpy activation corrections.
  * **Implicit Solvent Models**: Water, DMSO, Acetonitrile, Ethanol, DCM, THF, Toluene, or Vacuum. Computes electrostatic dielectric screening ($\varepsilon_r$ from 2.38 to 80.1) and attenuates transition-state free energy barriers.
  * **Molecular Charge & Spin Multiplicity**: Full control over ionic charges (-3 to +3) and spin states (singlet, doublet, triplet, quartet) for accurate Hamiltonian projection.
* **Catalyst Configuration**:
  * **Catalyst Toggle**: Switch between uncatalyzed and catalyzed reaction pathways.
  * **Literature Catalysts**: Presets for Pt/C, Pd/C, Ru/C, Zeolite H-ZSM-5, Grubbs-II, Wilkinson's catalyst, organocatalysts, and enzymes.
  * **Activation Barrier Reduction ($\Delta E_{cat}$)**: 0 to 50 kcal/mol barrier lowering with live turnover frequency (TOF) estimation.
* **Quantum Theory & Optimizer**:
  * **Methods & Basis Sets**: Semi-empirical, MLIP, DFT, HF, Post-HF across STO-3G, 6-31G*, def2-SVP, def2-TZVP.
  * **Convergence Criteria**: SCF convergence ($10^{-4}$ to $10^{-8}$ Hartree) and force convergence $f_{max}$ (0.001 to 0.05 eV/Å).
  * **Algorithms**: L-BFGS, FIRE, QuickMin, and Steepest Descent with step-count limits (10 to 500).
* **Reaction Path & Post-TS Analysis**:
  * **NEB Discretization**: 5 to 101 images controlling both FastAPI backend solvers and in-browser neural trajectory interpolation.
  * **Spring Constant ($k_{spring}$)**: 0.01 to 1.0 eV/Å² for inter-image stiffness along the MEP.
  * **TS Localization**: CI-NEB (Climbing Image), Dimer Method, Sella saddle search, and Berny TS.
  * **Zero-Point Energy (ZPE)**: Thermal vibrational energy offset with empirical frequency scaling factor (0.8 to 1.05).
  * **Frequency / IR Normal Modes**: Mass-weighted Hessian diagonalization to isolate the transition state's imaginary frequency ($\nu^\ddagger < 0$) and render simulated IR stick spectra.

### 5. 💊 Clinical Pharmacopeia & Veterinary (DVM) Medicine Suite
* **Human Medicine Benchmarks (MBBS & Pharm-D)**: 25+ essential therapeutics with complete reaction coordinates, intermediate transition states, and IUPAC nomenclature:
  * **Paracetamol** (Acetaminophen via $p$-aminophenol acylation)
  * **Aspirin** (Salicylic acid acetylation)
  * **Ibuprofen** (Friedel-Crafts acylation / Darzens sequence)
  * **Amoxicillin** ($\beta$-lactam ring functionalization)
  * **Metformin** (Biguanide condensation)
  * **Omeprazole** (Proton-pump inhibitor sulfide oxidation)
  * **Ciprofloxacin** (Fluoroquinolone nucleophilic substitution)
  * **Atorvastatin** (HMG-CoA reductase inhibitor core construction)
  * **Losartan** (Angiotensin II receptor antagonist tetrazole synthesis)
  * **Salbutamol** (Albuterol $\beta_2$-adrenoceptor agonist)
* **Veterinary Medicine Benchmarks (DVM)**: 10+ essential animal therapeutics:
  * **Ivermectin** (Antiparasitic macrolide semi-synthesis)
  * **Flunixin Meglumine** (Equine NSAID cycloaddition)
  * **Carprofen** (Canine anti-inflammatory carbazole synthesis)
  * **Enrofloxacin** (Veterinary fluoroquinolone)
  * **Phenylbutazone** (Equine NSAID condensation)
  * **Meloxicam** (Enolic acid veterinary anti-inflammatory)
  * **Marbofloxacin** (Veterinary fluoroquinolone antimycobacterial)
* **Dynamic Medical Dossier Card**:
  * Automatically detects medicinal compounds and qualifies WHO Model List of Essential Medicines tags.
  * Renders Mechanism of Action (MoA), clinical indications, target species (Canine, Feline, Equine, Bovine, Human), dosage forms, routes of administration, and direct clickable **DOI Literature Citations**.

### 6. 🧪 Polymer Chemistry & Expanded Cloud Library
* **Industrial Polymer Synthesis**: Complete reaction coordinates and intermediate transition states for commodity and engineering polymers:
  * Polyethylene Terephthalate (PET condensation)
  * Nylon 6,6 (Polyamidation)
  * Polystyrene (Free-radical polymerization)
  * Polylactic Acid (PLA ring-opening)
  * Polyurethane (Diisocyanate polyaddition)
  * Bakelite (Phenol-formaldehyde crosslinking)
  * Polymethyl Methacrylate (PMMA)
  * Polytetrafluoroethylene (PTFE)
* **200,000+ Cloud Reaction Library**:
  * Search and filter across 16 reaction classes and 4 educational tiers (High School, Undergraduate, Graduate, Research).
  * Direct DOI hyperlinks to peer-reviewed journal literature.
  * **Headless YouTube Scraper**: Streamlined search using `youtube_explode_dart` without API quotas or external billing.

### 7. 🧬 In-Browser Neural Trajectory Compressor
* **Transformer Reaction Compressor** (`TransformerReactionCompressor`):
  * Utilizes geometric multi-head self-attention and collision-free frame decoding directly in Dart/Web.
  * Dynamically resamples and decompresses NEB trajectories to exactly match the researcher's configured `neb_images` (from 5 to 101 frames).
  * Implements dielectric solvent electrostatic screening ($\varepsilon_r$) and thermal activation entropy modulation during frame decoding.
  * Enforces steric clash avoidance with minimum covalent radii constraints, guaranteeing physically valid molecular geometries across every intermediate frame.

### 8. Reaction Dashboards & Analytics
* **Energy Profile Graphs**: Interactive 2D line charts plotting the reaction coordinate against relative potential energy, activation energy $\Delta E^\ddagger$, and reaction enthalpy $\Delta H^\ddagger$.
* **Arrhenius Kinetics Plots**: Interactive $\ln(k)$ vs $1/T$ plots dynamically calculated across user temperatures.
* **Simulated IR Spectra**: Normal mode vibrational stick spectrum highlighting the unique imaginary frequency characterizing the transition state.
* **Thermodynamic Readout Cards**: Live Gibbs free energy $\Delta G^\ddagger$, enthalpy $\Delta H^\ddagger$, entropy $\Delta S^\ddagger$, rate constant $k$, dipole moment, polarisability, and HOMO-LUMO gap.

### 9. Hybrid ML/MM Molecular Dynamics
* **Complete Peptide System**: Natively handles both `.pdb` and `.xyz` uploads. Automatically solvates, neutralizes, and adds missing hydrogens using OpenMM `Modeller`.
* **Dynamic MLIP Masking**: Custom PyTorch TorchScript masking restricts MLIP evaluation solely to peptide atoms, letting AMBER19 handle solvent calculations.
* **Browser Execution**: Launch and inspect GPU-accelerated MD jobs directly from the web client.

### 10. Scientific Theming
Seven presets grounded in real laboratory and publication conventions:
* **Dark Matter** — Deep field low-glare default for long optimisation runs
* **Quantum Blue** — Cherenkov blue, metallic renderer
* **Neon Synth** — Laser pink + cyan on violet, translucent atoms
* **Electron Cloud** — Teal isosurface palette, high VDW opacity
* **Spectroscopy** — Low-glare slate with warm IR / violet UV-Vis accents
* **Scientific Light** — Print-quality light theme for figures and projectors
* **Journal Mono** — Greyscale-first, Okabe–Ito colour-blind-safe plots

---

## 🛠️ Stack & Architecture

* **Frontend**: Flutter Web · Dart 3 · `dart:js_interop` · WebGL / NGL
* **State Architecture**: `provider` (`ChangeNotifier` + `ValueNotifier`)
* **Backend as a Service (BaaS)**: Google Firebase (Authentication, Firestore, Hosting)
* **MLIP Microservices**: FastAPI (Python 3.10+), PyTorch, ASE (Atomic Simulation Environment)
* **Chemistry Engine**: Custom multi-format CJSON/CML/SDF/XYZ parser, Avogadro 2 Python bridge, OpenMM
* **UI/UX**: Material 3, `flutter_staggered_animations`, custom 2D/3D Canvas painters

---

## ⚙️ Running Locally

1. Ensure the [Flutter SDK](https://flutter.dev/docs/get-started/install) is installed.
2. Clone the repository and install dependencies:
   ```bash
   git clone https://github.com/aliasghar08/Quantum-Forge.git
   cd Quantum-Forge/quantum_forge
   flutter pub get
   ```
3. Run the application locally on Chrome:
   ```bash
   flutter run -d chrome
   ```

Quality gates:
```bash
flutter analyze   # 0 issues (clean)
flutter test      # 387 passing tests
```

---

## 🌐 Live Deployment

Quantum Forge is deployed globally via Firebase Hosting:
[https://quantom-forge.web.app](https://quantom-forge.web.app)

---

## 👤 Author

Developed by **Ali Asghar**  
Contact: aliasgharinnocent@yahoo.com
