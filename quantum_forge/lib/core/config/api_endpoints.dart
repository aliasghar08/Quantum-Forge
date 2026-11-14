// ============================================================================
// ApiEndpoints — single source of truth for compute-backend URLs
// ----------------------------------------------------------------------------
// Before this existed, `http://localhost:800x` was hard-coded in three places
// and shipped into the release bundle. From the HTTPS Firebase origin that
// request is blocked / refused, and the browser reports it only as the opaque
// `TypeError: Failed to fetch`.
//
// Rules enforced here:
//   * Debug builds  -> `http://127.0.0.1:<port>` (local uvicorn dev servers).
//   * Release builds-> an `https://` URL only. Loopback addresses never leak
//     into a release build, and any plain `http://` host is upgraded.
//   * `--dart-define=API_BASE_URL=https://...` overrides both, for staging or
//     for pointing a release build at a different deployment:
//         flutter build web --release --dart-define=API_BASE_URL=https://host
//   * `--dart-define=PROD_API_BASE_URL=...` changes only the release default.
//
// An empty result means "no usable backend": callers fall back to the
// on-device Transformer engine instead of issuing a doomed request.
// ============================================================================

import 'package:flutter/foundation.dart' show kDebugMode;

class ApiEndpoints {
  const ApiEndpoints._();

  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  /// Hosted compute backend used by release builds. One service answers every
  /// MLIP: the model is chosen by the `mlip_model` field of the request.
  ///
  /// Migrated from Hugging Face Spaces to Google Cloud Run on 2026-10-07.
  /// The GNN service is deployed at:
  ///   gcloud run services describe quantom-forge-gnn --region us-central1
  static const String productionBaseUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: 'https://quantom-forge-gnn-227207155336.us-central1.run.app',
  );

  /// Local development servers, one per MLIP microservice.
  static const Map<String, int> _localPorts = {
    'tx1-fastapi': 8005,
    'MACE-MP-0': 8001,
    'MACE-OFF23': 8001,
    'CHGNet': 8002,
    'ANI-2x': 8003,
    'GFN2-xTB': 8004,
  };

  /// Dedicated Google Cloud Run Hemodynamics & FFR/iFR Backend
  static const String cardioCathBackendUrl = String.fromEnvironment(
    'CARDIOCATH_API_BASE_URL',
    defaultValue: 'https://cardiocath-backend-227207155336.us-central1.run.app',
  );

  /// Dedicated Google Cloud Run Neurovascular & CSF Physics Backend
  static const String neurolabBackendUrl = String.fromEnvironment(
    'NEUROLAB_API_BASE_URL',
    defaultValue: 'https://neurolab-backend-227207155336.us-central1.run.app',
  );

  /// NeuroLab Hemodynamics & Circle of Willis Autoregulation URL
  static String get neuroHemodynamicsUrl =>
      '${sanitize(neurolabBackendUrl)}/api/neuro/hemodynamics';

  /// NeuroLab 500 Hz Multi-Channel IONM Oscilloscope Synthesis URL
  static String get neuroIonmOscilloscopeUrl =>
      '${sanitize(neurolabBackendUrl)}/api/neuro/ionm-oscilloscope';

  /// NeuroLab TCD Lindegaard Vasospasm Analysis URL
  static String get neuroTcdVasospasmUrl =>
      '${sanitize(neurolabBackendUrl)}/api/neuro/tcd-vasospasm';

  /// NeuroLab qEEG Spectral & Seizure Dynamics URL
  static String get neuroQeegSpectralUrl =>
      '${sanitize(neurolabBackendUrl)}/api/neuro/qeeg-spectral';

  /// NeuroLab EMG & Nerve Conduction Study (NCS) URL
  static String get neuroEmgNcsUrl =>
      '${sanitize(neurolabBackendUrl)}/api/neuro/emg-ncs';

  /// NeuroLab Endovascular Flow Diverter WSS CFD URL
  static String get neuroFlowDiverterUrl =>
      '${sanitize(neurolabBackendUrl)}/api/neuro/aneurysm-flow-diverter';

  /// NeuroLab BBB Permeability & CNS MPO Molecular Screener URL
  static String get neuroBbbPredictUrl =>
      '${sanitize(neurolabBackendUrl)}/api/neuro/bbb-predict';

  /// NeuroLab In-Silico Virtual Neuro-ICU Cohort Simulation URL
  static String get neuroResearchCohortUrl =>
      '${sanitize(neurolabBackendUrl)}/api/neuro/research-cohort';

  /// CardioNephroGNN: Multi-target cardio-renal drug affinity and hERG cardiotoxicity prediction
  static String get cardioNephroPredictUrl =>
      '${sanitize(cardioCathBackendUrl)}/api/cardio-nephro/predict';

  /// CardioNephroGNN benchmark presets
  static String get cardioNephroPresetsUrl =>
      '${sanitize(cardioCathBackendUrl)}/api/cardio-nephro/presets';

  /// WebSocket URL for real-time hemodynamics streaming
  static String get cardioCathWebSocketUrl {
    final base = sanitize(cardioCathBackendUrl);
    if (base.startsWith('https://')) {
      return 'wss://${base.substring(8)}/ws/hemodynamics';
    } else if (base.startsWith('http://')) {
      return 'ws://${base.substring(7)}/ws/hemodynamics';
    }
    return 'wss://cardiocath-backend-227207155336.us-central1.run.app/ws/hemodynamics';
  }

  /// True for hosts that only exist on the user's own machine.
  static bool isLoopback(String url) {
    final host = Uri.tryParse(url.trim())?.host.toLowerCase() ?? '';
    return host == 'localhost' || host == '127.0.0.1' || host == '::1' ||
        host == '[::1]' || host == '0.0.0.0';
  }

  /// Normalises [url] for the current build mode.
  ///
  /// Returns '' when the URL cannot be used safely (loopback in release).
  static String sanitize(String url, {bool? debug}) {
    final isDebug = debug ?? kDebugMode;
    var out = url.trim();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    if (out.isEmpty) return '';
    if (!out.contains('://')) out = 'https://$out';
    if (isDebug) return out;
    if (isLoopback(out)) return '';
    if (out.startsWith('http://')) out = 'https://${out.substring(7)}';
    return out;
  }

  /// Resolves the backend base URL for [mlipModel].
  ///
  /// Precedence: [userOverride] (Settings) > `API_BASE_URL` > build default.
  static String forModel(
    String mlipModel, {
    String userOverride = '',
    bool? debug,
  }) {
    final isDebug = debug ?? kDebugMode;
    for (final candidate in [userOverride, _envOverride]) {
      final clean = sanitize(candidate, debug: isDebug);
      if (clean.isNotEmpty) return clean;
    }
    if (isDebug) {
      final port = _localPorts[mlipModel] ?? _localPorts['tx1-fastapi']!;
      return 'http://127.0.0.1:$port';
    }
    return sanitize(productionBaseUrl, debug: false);
  }
}