# Quantom Forge 🧪⚛️

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Web-4285F4?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Web" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
</p>

**Quantom Forge** is an AI-assisted quantum chemistry optimisation and visualisation
workstation built **for the web** with Flutter. It gives researchers and students a
single browser dashboard for building molecules, modelling transition states, and
inspecting thermodynamic and kinetic results — with a two-way bridge to desktop
**Avogadro 2**.

## 🌐 Web-first platform

Quantom Forge targets the browser. WebGL and Flutter Web deliver the whole
computational-chemistry surface without a desktop install, on Windows, macOS or
Linux.

## 🚀 Features

### 1. 3D interactive builder
* **Inverse raycasting** — click into the 3D void to place atoms; drag from an atom
  to grow a bond at the ideal covalent distance.
* **Element picker** over the full periodic table with CPK colours and covalent /
  van-der-Waals radii.
* **Force-field relaxation** while you draw (toggleable), plus orbit/zoom camera
  controls and three atom representations (ball & stick, space filling, wireframe).

### 2. Structure I/O — Avogadro 2 native
* **Reads** CJSON (Avogadro's native Chemical JSON), CML, XYZ, SDF and MOL.
* **Writes** CJSON, CML, SDF (V2000 connection table) and XYZ, with configurable
  coordinate precision and title lines.
* **Perceives bonds** from covalent radii with a valence-aware order refinement, so
  exported connection tables are chemically sensible rather than a flat atom list.
* **Multi-XYZ trajectories** — the whole NEB path exports as one file Avogadro
  animates image by image.

### 3. Transition-state modelling & animation

The animation reproduces **Avogadro 2's Animation Tool** (the *Player* tool) —
see [`AVOGADRO_ANIMATION_PARITY.md`](quantum_forge/AVOGADRO_ANIMATION_PARITY.md)
for the full control-by-control mapping, the upstream source each number came
from, and an honest account of where the render matches Avogadro and where it
deliberately does not.

* **WebGL playback through NGL**, using NGL's own impostor spheres and cylinder
  bonds with its built-in ambient/diffuse/specular shading, at
  `radiusScale 0.5 / aspectRatio 2.0`. Four display types: Ball and Stick,
  Licorice, Van der Waals and Wireframe.
* **Orthographic camera** with 4× MSAA, antialiasing, display-matched pixel ratio
  and matched clip planes — the settings that separate "fine on a laptop" from
  "publication-grade on a projector".
* **Two element palettes**, switchable from the header: Avogadro's own
  `element_color` table and the Jmol/CPK table NGL calls `element`. They differ on
  hydrogen, carbon and fluorine, by Avogadro's design.
* **Avogadro's Player panel** — `<` / `>` frame stepping, a 1-based `Frame: N/M`
  spin box, a frame slider, `Start:` / `End:` range controls, a
  `Dynamic bonding?` checkbox, a `Frame rate:` box in FPS (default 5, 0 remapped
  to 5), a `Play` ⇄ `Pause` button, and Avogadro's keyboard map
  (Space, ← →, Shift+← →, ↑ Start, ↓ End).
* **Discrete images, never interpolation.** An NEB image is a computed geometry;
  blending two of them would draw a structure no calculation produced. Looping
  wraps within `[Start, End]` exactly as `animate()` does upstream.
* **Dynamic bonding** re-perceives every bond from the current frame's
  coordinates using Avogadro's rule — covalent radii plus a 0.45 Å tolerance,
  hydrogen–hydrogen and the noble gases excluded — so a breaking bond really
  disappears.
* **An x/y/z orientation triad** in the corner, drawn in Flutter because NGL has
  no orientation widget.
* A research readout alongside it: frame, relative energy, absolute MACE energy,
  path progress, cycle duration, transition-state frame and live bond count.
* Energy-profile, Arrhenius and IR-spectrum plots drawn with the active theme's
  colour palette.

### 4. Reaction dashboards
* Energy profile (ΔE‡, ΔH‡), Arrhenius kinetics, simulated IR sticks.
* Live thermodynamic cards: Gibbs energy, enthalpy, entropy, rate constant, ZPE,
  dipole, HOMO–LUMO gap, polarisability, RMS gradient.

### 5. Hybrid ML/MM Molecular Dynamics
* **Complete Peptide System**: Natively handles both `.pdb` and `.xyz` uploads. Automatically solvates, neutralizes, and adds missing hydrogens using OpenMM `Modeller`.
* **Dynamic MLIP Masking**: Custom PyTorch TorchScript masking restricts the MLIP evaluation solely to the peptide atoms, letting AMBER19 handle the massive solvent box.
* **UI Integration**: Control simulation length dynamically from the 3D builder and launch GPU-accelerated jobs directly from the browser.

### 6. Cloud reaction library
* Firestore-backed library of textbook reactions (Grignard, Fischer esterification,
  Friedel–Crafts, Suzuki) with real-time search and filtering.
* **Headless YouTube Scraping**: Replaced the official Google YouTube Data API with a custom implementation using `youtube_explode_dart`. The app securely scrapes related videos directly from the browser context, entirely bypassing Google Cloud Billing and API key requirements.

### 7. Scientific theming
Seven presets, each grounded in a real convention rather than a colour preference.
A theme is not just a `ColorScheme` — it also supplies the palette used by the
hand-written 2D/3D painters and the chart series colours.

| Preset | Family | Idea |
| --- | --- | --- |
| Dark Matter | Deep field | Low-glare default for long optimisation runs |
| Quantum Blue | Orbital | Cherenkov blue, metallic renderer |
| Neon Synth | Spectroscopy | Laser pink + cyan on violet, translucent atoms |
| Electron Cloud | Density | Teal isosurface palette, high VDW opacity |
| Spectroscopy | Spectroscopy | Low-glare slate with warm IR / violet UV-Vis accents |
| Scientific Light | Publication | Print-quality light theme for figures and projectors |
| Journal Mono | Publication | Greyscale-first, Okabe–Ito colour-blind-safe plots |

Themes persist across sessions; <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>T</kbd> cycles
them.

### 8. Settings that actually apply
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

### 9. Avogadro 2 bridge
Two directions, because Avogadro 2 has no URL-open hook:

* **Avogadro → web.** The bundled plugin (`avogadro_plugin/`) sends the open molecule
  as CJSON through a deep link; the editor opens with it pre-loaded (or a banner
  offers to, if auto-load is off). The payload is stripped from the address bar
  afterwards so a refresh does not re-import it.
* **Web → Avogadro.** *Export* writes CJSON/CML/SDF/XYZ files, *Export trajectory*
  writes the multi-XYZ path, and *Export bundle (.zip)* packages trajectory, final
  structure (XYZ + CJSON) and an energy manifest. See
  [`avogadro_plugin/README.md`](quantum_forge/avogadro_plugin/README.md).

### 10. Accounts
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
flutter analyze   # must be clean
flutter test      # 93 tests
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
Quantom-Forge/
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
├── ani2x-backend/        # ANI-2x Deep Learning Potential service (Port 8002)
├── chgnet-backend/       # CHGNet Universal Potential service (Port 8003)
├── gfn2-xtb-backend/     # GFN2-xTB Semi-Empirical QM service (Port 8004)
├── tx1-fastapi-backend/  # Transition1x GNN compute service (Port 8005)
└── .github/              # CI/CD Workflows for automated analysis and deployment
```

## 👤 Author

Developed by **Ali Asghar**
