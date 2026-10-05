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
  static const String productionBaseUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: 'https://aliasgharinnocent-tx1-backend.hf.space',
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
