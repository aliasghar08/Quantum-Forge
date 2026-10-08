# Quantum Forge — Comprehensive Codebase Audit Report

**Date:** 2026-10-08  
**Scope:** Full Stack Monorepo (`quantum_forge/` Flutter Web, `tx1-fastapi-backend/` FastAPI GNN service, Cloud Run deployment, Cloud Firestore rules & indexes, Firebase Hosting)  
**Auditor:** Antigravity Codebase Auditor  

---

## 1. Executive Summary

Quantum Forge has made significant progress in migrating its compute and presentation layers from legacy third-party hosts (Render and Hugging Face Spaces) to a unified Google Cloud Platform (GCP) and Firebase infrastructure. The frontend is a sophisticated Flutter Web application communicating with a FastAPI backend on Google Cloud Run (`https://quantom-forge-gnn-227207155336.us-central1.run.app`) and Firebase services (`https://quantom-forge.web.app`). The transition state search engine integrates Transition1x GNN with external Machine Learning Interatomic Potentials (MLIP) and provides an end-to-end bridge to Avogadro 2.

However, the architecture currently exhibits severe vulnerabilities, data integrity risks, and scalability bottlenecks that jeopardize production stability. Most notably, Cloud Firestore security rules permit unrestricted public write and delete access to the entire reaction template library (`/library/{templateId}`), leaving core application data vulnerable to defacement or deletion by unauthenticated actors on the internet. Furthermore, the frontend client executes an un-throttled library seeding routine on every application cold start, which—combined with redundant profile synchronization on all authentication checks—creates massive write amplification against Firestore that can rapidly exhaust the free-tier daily write quota (20,000 writes/day).

At the compute layer, the backend relies on an ephemeral, in-memory dictionary (`_reactions = {}`) for all reaction tracking, progress reporting, and DFT result attachments. Because Cloud Run instances scale down when idle, restart during deployments, and cannot share memory across multiple instances, user reaction progress and attached quantum chemical data are regularly lost. Furthermore, the deployed Cloud Run service has its CORS origin set to a wildcard (`*`), runs on an over-privileged default Compute Engine service account, and retains legacy Celery/Redis endpoints that fail immediately with 500 errors because no message broker runs within the container.

### Top 3 Risks

1. **Catastrophic Public Data Deletion and Tampering (QF-001):** The Firestore rule `match /library/{templateId} { allow read, write: if true; }` allows any internet user with knowledge of the project ID to overwrite, corrupt, or delete all public reactions.
2. **Ephemeral In-Memory Compute State & Data Loss (QF-004, QF-005):** Reactions and DFT attachments stored only in Python RAM (`_reactions`) are wiped during container eviction, idle scaling, or deployment, leading to perpetual polling hangs in the frontend and irrecoverable loss of researcher calculations.
3. **Firestore Quota Exhaustion & Write Amplification (QF-002, QF-003):** Cold-start auto-seeding writes 15 documents on every browser load, while `FirebaseAuthService` triggers document reads and writes on every `isAuthenticated()` and `getUserId()` query. Normal user traffic can exhaust daily write quotas within hours, disabling logins and reaction submissions.

---

## 2. Findings Table

| ID | Severity | Category | Title | Location | Evidence | Impact |
|---|---|---|---|---|---|---|
| **QF-001** | `CRITICAL` | `security` | Public Write/Delete Permitted on Firestore Library | `quantum_forge/firestore.rules:34-36` | `match /library/{templateId} { allow read, write: if true; }` | Any unauthenticated user can delete, corrupt, or inject malicious reaction templates. |
| **QF-002** | `HIGH` | `data` | Unconditional Auto-Seeding on Every Cold Start Exhausts Quota | `quantum_forge/lib/main.dart:122-135`, `firestore_library_repository.dart:197-208` | `_seedLibrary()` called unawaited in `initialiseCloudFeatures()` on every startup | 15 unconditional document writes per page reload. 1,300 visitors completely deplete the 20k/day free-tier quota. |
| **QF-003** | `HIGH` | `data` | Firestore Profile Sync Write Amplification on Every Auth Check | `quantum_forge/lib/core/services/firebase_auth_service.dart:107, 119` | `unawaited(_syncUserProfile(user))` invoked inside both `getUserId()` and `isAuthenticated()` | Multiplies Firestore reads and writes on UI navigation and reaction dispatches, increasing billing and quota exhaustion. |
| **QF-004** | `CRITICAL` | `backend` | In-Memory Reaction Dict Wiped on Cloud Run Scale-Out, Eviction, or Deploy | `tx1-fastapi-backend/main.py:232, 368-381` | `_reactions = {}` in-memory global dict | Polling returns 404 if hitting a different instance; reactions and attached DFT results permanently vanish on container restart. |
| **QF-005** | `HIGH` | `backend` | Celery/Redis Endpoints Inoperable on Stateless Cloud Run | `tx1-fastapi-backend/main.py:577-659`, `worker_hybrid.py:18-22` | `broker="redis://localhost:6379/0"` with no Redis broker in container | Any call to `/simulate/hybrid-md` crashes with connection refused 500 error. |
| **QF-006** | `HIGH` | `security` | Wildcard CORS Allowed Origin Configured in Production Cloud Run | Cloud Run Environment `T1X_ALLOWED_ORIGINS` | `spec.containers[0].env[name="T1X_ALLOWED_ORIGINS"].value="*"` | Allows any untrusted website to make cross-origin POST requests to the backend compute API. |
| **QF-007** | `MEDIUM` | `backend` | Unnotified Fallback Model Mixes Incompatible Energy Surfaces | `tx1-fastapi-backend/main.py:199-204, 321-325` | `except Exception: fallback = registry.get("tx1-fastapi"); return fallback.energy_ev(...)` | Frame-by-frame fallback causes energy profiles with mismatched reference scales, distorting calculated barriers. |
| **QF-008** | `HIGH` | `frontend` | Reaction Animation Widget Rebuilds Full Card Subtree per Frame | `quantum_forge/lib/core/widgets/reaction_animation_widget.dart:309-383`, `reaction_animation_state_playback.dart:73` | `setState(() => _frame = clamped);` triggers full widget `build()` | High-frequency CPU spikes, frame drops, and unnecessary garbage collection at 5–30 Hz playback. |
| **QF-009** | `MEDIUM` | `frontend` | Debug Backend URL Resolution Shadows Custom URL Equal to Default | `quantum_forge/lib/state/reaction_provider_backend.dart:18-21` | `if (explicitOverride.isNotEmpty && explicitOverride != kDefaultComputeBackendUrl)` | In debug builds, typing or keeping the production Cloud Run URL is discarded, routing to 127.0.0.1:8005. |
| **QF-010** | `MEDIUM` | `frontend` | Unsafe Forced JSON Casts in `ReactionStatusResponse.fromJson` | `quantum_forge/lib/features/reaction_runner/data/models/reaction_models.dart:166-168` | `reactionId: json['reaction_id'] as String`, `state: parseState(json['state'] as String)` | Runtime `TypeError` crash if backend poll response omits a field or returns null. |
| **QF-011** | `MEDIUM` | `security` | HTTP Header Injection Risk in `export-ts` Filename Header | `tx1-fastapi-backend/main.py:516-518` | `headers={"Content-Disposition": f'attachment; filename="{reaction_id}_mlip_ts.xyz"'}` | Unsanitized `reaction_id` in header allows potential header injection or response splitting on reverse proxies. |
| **QF-012** | `MEDIUM` | `backend` | Unbounded In-Memory Reaction Growth and Memory Leak | `tx1-fastapi-backend/main.py:232, 330` | `_reactions` retains 121 XYZ strings (~200 KB) per reaction with no TTL or eviction | Container memory continually grows under load, risking Cloud Run Out-Of-Memory (OOM) termination. |
| **QF-013** | `MEDIUM` | `infra` | Bloated Backend Docker Image (~5 GB with Unused CUDA Packages) | `tx1-fastapi-backend/Dockerfile:16-17`, `requirements.txt:5` | `pip install -r requirements.txt` pulling standard PyPI CUDA torch | Prolonged cold start pull times (30–45s) and unnecessary Artifact Registry storage costs. |
| **QF-014** | `MEDIUM` | `infra` | Cloud Run Uses Default Compute Engine Service Account | Cloud Run Service Spec | `serviceAccountName: 227207155336-compute@developer.gserviceaccount.com` | Breaches least-privilege principles; compromised container inherits project-wide Editor permissions. |
| **QF-015** | `LOW` | `infra` | Missing Cloud Run Liveness and Readiness Probes | Cloud Run Service Spec | `startupProbe` configured, but no `livenessProbe` | Container deadlocks or asyncio worker thread hangs are not detected or restarted by Cloud Run. |
| **QF-016** | `LOW` | `infra` | Missing Cache-Control Headers in Firebase Hosting Config | `quantum_forge/firebase.json:29-42` | No `headers` section specifying cache lifetimes for SPA assets | Browsers cache old `index.html` and service workers, serving outdated bundles to returning users. |
| **QF-017** | `LOW` | `backend` | Dead Code `_compute_single_frame` | `tx1-fastapi-backend/main.py:260-267` | Function defined but not referenced anywhere in codebase | Confusing redundant dead code left after refactoring inference to `asyncio.to_thread`. |
| **QF-018** | `LOW` | `security` | Internal Stack and Exception Reflection in Global 500 Handler | `tx1-fastapi-backend/main.py:100-104` | `return JSONResponse(..., content={"detail": f"{type(exc).__name__}: {exc}"})` | Leaks internal paths, library versions, and model exceptions to external clients. |
| **QF-019** | `LOW` | `data` | Dead Firestore Rules for Deprecated `jobs/{jobId}` Collection | `quantum_forge/firestore.rules:22-24` | `match /jobs/{jobId} { allow read, write: if request.auth != null; }` | Codebase does not query or write to `jobs`; obsolete security rule creates confusion. |
| **QF-020** | `LOW` | `docs` | Stale and Misplaced `Dockerfile.save` in Flutter Directory | `quantum_forge/Dockerfile.save` | Misplaced 19-line Python Dockerfile in frontend root | Clutters source tree and violates monorepo hygiene. |
| **QF-021** | `MEDIUM` | `testing` | Lack of Backend CI Pipeline & Automated Deployments | `.github/workflows/dart.yml` | Only runs `flutter analyze` and `flutter test` | Backend code changes are merged without automated linting, unit tests, or container validation. |
| **QF-022** | `LOW` | `observability` | Absence of Structured Logging and Trace Correlation | `tx1-fastapi-backend/main.py` | Uses raw `print()` statements without severity, timestamps, or trace context | Impossible to filter errors reliably in Cloud Logging or correlate client requests with backend spans. |

---

## 3. Detailed Findings

### QF-001: Public Write/Delete Permitted on Firestore Library
- **Severity:** `CRITICAL`
- **Category:** `security`
- **Location:** `quantum_forge/firestore.rules:34-36`
- **Evidence:**
  ```javascript
  match /library/{templateId} {
    allow read, write: if true;
  }
  ```
- **Reproduction:** Issue a `DELETE` or `SET` request against `https://firestore.googleapis.com/v1/projects/quantom-forge/databases/(default)/documents/library/<templateId>` using any REST client without an `Authorization` header. Firestore accepts the request and deletes or replaces the document.
- **Root Cause:** Permissive rule was intentionally introduced to allow the client-side `autoSeedMedicalLibrary()` script in `main.dart` to write seed documents without requiring an authenticated admin session.
- **Suggested Fix:** Restrict `/library/{templateId}` writes to authenticated administrator claims (`request.auth.token.admin == true`), or migrate database seeding to an administrative Cloud Function or offline script using the Firebase Admin SDK with service account credentials.

---

### QF-002: Unconditional Auto-Seeding on Every Cold Start Exhausts Quota
- **Severity:** `HIGH`
- **Category:** `data`
- **Location:** `quantum_forge/lib/main.dart:119-135`, `quantum_forge/lib/features/reaction_library/data/firestore_library_repository.dart:197-208`
- **Evidence:**
  ```dart
  // main.dart
  unawaited(_seedLibrary());
  
  // firestore_library_repository.dart
  final jsonStr = await rootBundle.loadString('assets/medical_reactions.json');
  final list = jsonDecode(jsonStr) as List<dynamic>;
  // ...
  final count = await seedLibrary(templates); // Executes batch.set() for every template
  ```
- **Reproduction:** Open the application in Chrome with DevTools Network tab active or monitor Firestore console writes. Every page reload dispatches a batch write of 15 documents into `/library`, regardless of whether the documents already exist.
- **Root Cause:** `autoSeedMedicalLibrary()` does not perform an existence check or use a local storage flag (`has_seeded`) before committing batch writes.
- **Suggested Fix:** Remove runtime client-side seeding completely from `main.dart`. Seed templates during CI/CD or via an administrator script. If client fallback is necessary, check document existence or record a local flag in `AppStorage` to execute at most once per client.

---

### QF-003: Firestore Profile Sync Write Amplification on Every Auth Check
- **Severity:** `HIGH`
- **Category:** `data`
- **Location:** `quantum_forge/lib/core/services/firebase_auth_service.dart:107, 119`
- **Evidence:**
  ```dart
  @override
  Future<String> getUserId() async {
    _ensureListener();
    final user = _auth.currentUser;
    if (user != null) {
      unawaited(_syncUserProfile(user));
      return user.uid;
    }
    return '';
  }

  @override
  Future<bool> isAuthenticated() async {
    _ensureListener();
    final user = _auth.currentUser;
    if (user != null) {
      unawaited(_syncUserProfile(user));
    }
    return user != null;
  }
  ```
- **Reproduction:** Navigate between screens in the application or dispatch a reaction. Inspect Firestore telemetry; each call to `getUserId()` or `isAuthenticated()` issues a document lookup (`docRef.get()`) followed by a write (`docRef.set()`).
- **Root Cause:** `_syncUserProfile` was added to `getUserId()` and `isAuthenticated()` under the assumption that sessions needed eager synchronization, duplicating the subscription listener on `authStateChanges()`.
- **Suggested Fix:** Remove `unawaited(_syncUserProfile(user))` from `getUserId()` and `isAuthenticated()`. Rely solely on `authStateChanges()` and explicit sign-in/sign-up events, with a debounce check (e.g., sync at most once every 24 hours per session).

---

### QF-004: In-Memory Reaction Dict Wiped on Cloud Run Scale-Out, Eviction, or Deploy
- **Severity:** `CRITICAL`
- **Category:** `backend`
- **Location:** `tx1-fastapi-backend/main.py:232, 368-381`
- **Evidence:**
  ```python
  _reactions = {}
  # ...
  @app.post("/reactions/submit")
  async def submit_reaction(req: ReactionRequest, background_tasks: BackgroundTasks):
      reaction_id = str(uuid.uuid4())
      _reactions[reaction_id] = { ... }
      background_tasks.add_task(run_reaction, reaction_id, req)
      return {"reaction_id": reaction_id}
  ```
- **Reproduction:** Submit a reaction via `/reactions/submit`. Restart the Cloud Run revision or trigger a new deployment. Send `GET /reactions/{reaction_id}`. The endpoint responds with `404 Not Found`. Similarly, if Cloud Run `maxScale` is increased beyond 1, requests routed to another instance return 404.
- **Root Cause:** State is stored in Python process memory rather than an external persistent store (such as Firestore or Memorystore/Redis).
- **Suggested Fix:** Persist reaction documents, progress, and DFT attachments directly to Cloud Firestore from the backend or store session state in a centralized Redis cache.

---

### QF-005: Celery/Redis Endpoints Inoperable on Stateless Cloud Run
- **Severity:** `HIGH`
- **Category:** `backend`
- **Location:** `tx1-fastapi-backend/main.py:577-659`, `tx1-fastapi-backend/worker_hybrid.py:18-22`
- **Evidence:**
  ```python
  # worker_hybrid.py
  celery_app = Celery(
      "hybrid_md_worker",
      broker="redis://localhost:6379/0",
      backend="redis://localhost:6379/0"
  )
  ```
- **Reproduction:** Issue a `POST /simulate/hybrid-md` request to the Cloud Run backend. The endpoint throws `redis.exceptions.ConnectionError: Error 111 connecting to localhost:6379. Connection refused.` and returns an unhandled HTTP 500 error.
- **Root Cause:** The container only runs `uvicorn main:app`. No Redis service runs inside the container, and no managed Redis instance (Cloud Memorystore) is configured.
- **Suggested Fix:** Either provision a managed Redis instance (or run background tasks asynchronously in-process via `asyncio.to_thread` / Cloud Tasks), or disable/remove the `/simulate/*` endpoints from the web API until an asynchronous worker cluster is deployed.

---

### QF-006: Wildcard CORS Allowed Origin Configured in Production Cloud Run
- **Severity:** `HIGH`
- **Category:** `security`
- **Location:** Google Cloud Run Service Configuration (`T1X_ALLOWED_ORIGINS`)
- **Evidence:**
  ```yaml
  containers:
  - env:
    - name: T1X_ALLOWED_ORIGINS
      value: '*'
  ```
- **Reproduction:** Execute a curl preflight `OPTIONS` request with `Origin: https://malicious-website.com`. The backend responds with `Access-Control-Allow-Origin: *`.
- **Root Cause:** During troubleshooting of "TypeError: Failed to fetch", `T1X_ALLOWED_ORIGINS` was set to `*` in the Cloud Run service environment variables, overriding the strict origin whitelist in `main.py`.
- **Suggested Fix:** Update the Cloud Run environment variable to restrict origins strictly to `https://quantom-forge.web.app,https://quantom-forge.firebaseapp.com`.

---

### QF-007: Unnotified Fallback Model Mixes Incompatible Energy Surfaces
- **Severity:** `MEDIUM`
- **Category:** `backend`
- **Location:** `tx1-fastapi-backend/main.py:199-204, 321-325`
- **Evidence:**
  ```python
  def _eval_frame(frame_idx, numbers, coords):
      try:
          return calculator.energy_ev(numbers, coords)
      except Exception as exc:
          print(f"[MLIP] {calculator.name()} failed on frame {frame_idx}: {exc}")
          fallback = registry.get("tx1-fastapi")
          return fallback.energy_ev(numbers, coords)
  ```
- **Reproduction:** Provide a molecule containing elements unsupported by MACE or invoke an MLIP that fails on a specific geometry frame. The calculation silently switches to `tx1-fastapi` for that frame without failing the calculation or marking the mixed nature of the trajectory.
- **Root Cause:** Catch-all exception fallback was introduced to prevent server crashes, but it compromises physical validity: different potentials use different reference zero energies.
- **Suggested Fix:** If the selected MLIP fails, fail the entire calculation with an explanatory error, or switch the *entire* reaction to fallback from frame 0 while setting a clear `fallback_invoked: true` flag in the response metadata.

---

### QF-008: Reaction Animation Widget Rebuilds Full Card Subtree per Frame
- **Severity:** `HIGH`
- **Category:** `frontend`
- **Location:** `quantum_forge/lib/core/widgets/reaction_animation_widget.dart:309-383`, `reaction_animation_state_playback.dart:73`
- **Evidence:**
  ```dart
  void _showFrame(int frame) {
    if (!mounted) return;
    final clamped = frame.clamp(_startFrame, _endFrame);
    if (clamped == _frame) return;
    setState(() => _frame = clamped); // Rebuilds entire ReactionAnimationWidgetState
    _syncViewerFrame();
    _pushBondLabelsForFrame(clamped);
  }
  ```
- **Reproduction:** Run the Flutter application with the Performance Overlay enabled. Start reaction playback at 10–20 FPS. The entire card, including the header, canvas container, timeline, and controls, re-evaluates `build()` on every frame tick.
- **Root Cause:** Frame progress is stored directly on the top-level widget `State` rather than inside a scoped `ValueNotifier<int>` consumed only by the timeline and readout widgets.
- **Suggested Fix:** Encapsulate `_frame` in a dedicated `ValueNotifier<int>`. Use `ValueListenableBuilder` around the frame readout and slider, removing `setState` from the high-frequency ticker loop.

---

### QF-009: Debug Backend URL Resolution Shadows Custom URL Equal to Default
- **Severity:** `MEDIUM`
- **Category:** `frontend`
- **Location:** `quantum_forge/lib/state/reaction_provider_backend.dart:18-21`
- **Evidence:**
  ```dart
  final explicitOverride = (backendUrlProvider?.call() ?? '').trim();
  var url = settings.effectiveBackendUrl;
  if (explicitOverride.isNotEmpty &&
      explicitOverride != kDefaultComputeBackendUrl) {
    url = explicitOverride;
  }
  ```
- **Reproduction:** In debug mode, enter the production Cloud Run URL into Settings (or leave it as default). Dispatch a reaction. The app rejects `explicitOverride` because it equals `kDefaultComputeBackendUrl`, falling back to `settings.effectiveBackendUrl`, which in debug mode resolves to `http://127.0.0.1:8005`.
- **Root Cause:** The check `explicitOverride != kDefaultComputeBackendUrl` was intended to differentiate default from custom settings, but in debug mode it prevents testing the live backend.
- **Suggested Fix:** In `AppSettings.effectiveBackendUrl`, respect the configured URL if non-empty, and only fall back to localhost if `backendUrl` is empty.

---

### QF-010: Unsafe Forced JSON Casts in `ReactionStatusResponse.fromJson`
- **Severity:** `MEDIUM`
- **Category:** `frontend`
- **Location:** `quantum_forge/lib/features/reaction_runner/data/models/reaction_models.dart:166-168`
- **Evidence:**
  ```dart
  reactionId: json['reaction_id'] as String,
  state: parseState(json['state'] as String),
  progress: (json['progress'] as num).toDouble(),
  ```
- **Reproduction:** Receive a malformed or partial JSON response from the server missing `reaction_id` or `progress`. The parser immediately throws `TypeError: null is not a subtype of type 'String' in type cast`.
- **Root Cause:** Forced `as String` and `as num` casts rather than safe parsing (`as String? ?? ''`, `(json['progress'] as num?)?.toDouble() ?? 0.0`).
- **Suggested Fix:** Replace all forced casts in `ReactionStatusResponse.fromJson` with null-safe accessors and sensible defaults.

---

### QF-011: HTTP Header Injection Risk in `export-ts` Filename Header
- **Severity:** `MEDIUM`
- **Category:** `security`
- **Location:** `tx1-fastapi-backend/main.py:516-518`
- **Evidence:**
  ```python
  headers={
      "Content-Disposition": (
          f'attachment; filename="{reaction_id}_mlip_ts.xyz"'
      ),
      "Cache-Control": "no-store",
  }
  ```
- **Reproduction:** Pass a `reaction_id` containing CRLF sequences or quotes (`"`) via `/reactions/{reaction_id}/export-ts`.
- **Root Cause:** The path variable is interpolated directly into HTTP response headers without sanitization.
- **Suggested Fix:** Validate that `reaction_id` strictly conforms to a UUID regex (`^[0-9a-fA-F-]+$`) before using it in response headers.

---

### QF-012: Unbounded In-Memory Reaction Growth and Memory Leak
- **Severity:** `MEDIUM`
- **Category:** `backend`
- **Location:** `tx1-fastapi-backend/main.py:232, 347`
- **Evidence:**
  ```python
  _reactions[reaction_id].update({
      "trajectory_frames": frames, # 121 XYZ strings (~200 KB)
      ...
  })
  ```
- **Reproduction:** Submit 100 consecutive reactions to a single container instance. The memory usage grows by 20–50 MB without releasing older reactions.
- **Root Cause:** `_reactions` is an append-only dictionary with no TTL, size limit, or LRU eviction strategy.
- **Suggested Fix:** Implement an LRU cache or maximum capacity (e.g., retain at most 50 completed reactions), or evict reactions older than 2 hours.

---

### QF-013: Bloated Backend Docker Image (~5 GB with Unused CUDA Packages)
- **Severity:** `MEDIUM`
- **Category:** `infra`
- **Location:** `tx1-fastapi-backend/Dockerfile:16-17`, `tx1-fastapi-backend/requirements.txt:5`
- **Evidence:**
  ```dockerfile
  RUN pip install --no-cache-dir --upgrade pip \
   && pip install --no-cache-dir -r requirements.txt
  ```
  Standard PyPI `torch>=2.0.0` downloads full NVIDIA CUDA binaries.
- **Reproduction:** Run `docker build` on `tx1-fastapi-backend/Dockerfile`. The builder downloads ~2.5 GB of CUDA packages. The final image size exceeds 5 GB.
- **Root Cause:** Failure to specify `--extra-index-url https://download.pytorch.org/whl/cpu` for CPU-based container runtime environments.
- **Suggested Fix:** Install the CPU-only PyTorch wheel during image build. Reduces container image size by ~3.5 GB and slashes container cold-start pull times.

---

### QF-014: Cloud Run Uses Default Compute Engine Service Account
- **Severity:** `MEDIUM`
- **Category:** `infra`
- **Location:** Cloud Run Spec (`quantom-forge-gnn`)
- **Evidence:** `serviceAccountName: 227207155336-compute@developer.gserviceaccount.com`
- **Root Cause:** The default Compute Engine service account was assigned during deployment without creating a dedicated least-privilege IAM service account.
- **Suggested Fix:** Create a dedicated service account `quantom-forge-backend@quantom-forge.iam.gserviceaccount.com` with zero broad roles and only specific Firestore access permissions.

---

### QF-015: Missing Cloud Run Liveness and Readiness Probes
- **Severity:** `LOW`
- **Category:** `infra`
- **Location:** Cloud Run Service Configuration
- **Evidence:** Spec defines `startupProbe` but omits `livenessProbe`.
- **Root Cause:** Basic gcloud deployment flags only configured startup health checks.
- **Suggested Fix:** Add an HTTP liveness probe pointing to `/health` with a 30s period.

---

### QF-016: Missing Cache-Control Headers in Firebase Hosting Config
- **Severity:** `LOW`
- **Category:** `infra`
- **Location:** `quantum_forge/firebase.json:29-42`
- **Evidence:** The hosting stanza only defines rewrites; no `headers` block is present.
- **Root Cause:** Standard Flutter-generated `firebase.json` was left without custom caching directives.
- **Suggested Fix:** Add headers to `firebase.json` enforcing `Cache-Control: no-cache, no-store, must-revalidate` for `index.html` and `flutter_service_worker.js`.

---

### QF-017: Dead Code `_compute_single_frame`
- **Severity:** `LOW`
- **Category:** `backend`
- **Location:** `tx1-fastapi-backend/main.py:260-267`
- **Evidence:**
  ```python
  def _compute_single_frame(z_tensor, pos_tensor, mask_tensor):
      """Synchronous inference isolated from the asyncio event loop."""
      if model is None:
          return 0.0
      with torch.no_grad():
          energy = model(z_tensor, pos_tensor, mask_tensor)
          return energy.item()
  ```
- **Root Cause:** Left over from an earlier refactor before `_eval_frame` and `registry.get` were adopted.
- **Suggested Fix:** Delete the unused function.

---

### QF-018: Internal Stack and Exception Reflection in Global 500 Handler
- **Severity:** `LOW`
- **Category:** `security`
- **Location:** `tx1-fastapi-backend/main.py:100-104`
- **Evidence:**
  ```python
  return JSONResponse(
      status_code=500,
      content={"detail": f"{type(exc).__name__}: {exc}"},
  )
  ```
- **Root Cause:** Exception middleware reflects raw exception string to the client.
- **Suggested Fix:** Return a generic error message ("Internal server error") and log the raw exception string server-side.

---

### QF-019: Dead Firestore Rules for Deprecated `jobs/{jobId}` Collection
- **Severity:** `LOW`
- **Category:** `data`
- **Location:** `quantum_forge/firestore.rules:22-24`
- **Evidence:**
  ```javascript
  match /jobs/{jobId} {
    allow read, write: if request.auth != null;
  }
  ```
- **Root Cause:** Unused legacy rule from earlier Render background job implementation.
- **Suggested Fix:** Remove the rule block to keep security rules concise and maintainable.

---

### QF-020: Stale and Misplaced `Dockerfile.save` in Flutter Directory
- **Severity:** `LOW`
- **Category:** `docs`
- **Location:** `quantum_forge/Dockerfile.save`
- **Evidence:** A 19-line Python Dockerfile saved in the Flutter project root.
- **Root Cause:** Accidental editor save during Docker configuration.
- **Suggested Fix:** Delete the misplaced file.

---

### QF-021: Lack of Backend CI Pipeline & Automated Deployments
- **Severity:** `MEDIUM`
- **Category:** `testing`
- **Location:** `.github/workflows/dart.yml`
- **Evidence:** The repository only contains `dart.yml`, which runs Flutter analyzer and tests.
- **Root Cause:** CI was only set up for the frontend during initial repository scaffolding.
- **Suggested Fix:** Add a GitHub Actions workflow for the backend (`python.yml`) that runs `pytest` and linter checks on pull requests.

---

### QF-022: Absence of Structured Logging and Trace Correlation
- **Severity:** `LOW`
- **Category:** `observability`
- **Location:** `tx1-fastapi-backend/main.py`
- **Evidence:** Raw `print(...)` calls without JSON structure or correlation tokens.
- **Root Cause:** Standard logging library was not configured for Google Cloud Logging JSON payloads.
- **Suggested Fix:** Configure Python `logging` with a JSON formatter exporting `severity`, `timestamp`, and Google Cloud trace IDs.

---

## 4. Out-of-Scope Observations (Technical Debt & Code Smells)

1. **Duplicate Firestore Index Definitions (`quantum_forge/firestore.indexes.json`):**
   Lines 11–18 and 30–35 define the exact same composite index (`tags` CONTAINS, `name` ASCENDING). While Firestore ignores duplicates, it adds confusion to index management.
2. **Hardcoded Chemical Conversion Constants:**
   `_HARTREE_TO_KCAL_MOL = 627.5094740631` is defined in `main.py`, while `23.0605` (eV to kcal/mol) is hardcoded on line 337. These should be centralized in a chemistry constants module.
3. **Redundant Top-Level Navigation Drawer:**
   Theme switching is accessible via shortcut (<kbd>Ctrl+Shift+T</kbd>), the Settings screen, and the Drawer, each slightly duplicating state binding logic.
4. **Unencrypted `hfToken` Storage:**
   If a user inputs a Hugging Face token in Quantum Controls, it is written to browser `localStorage` in plaintext. While scoped to the origin, users should be warned that shared browsers can expose tokens.
