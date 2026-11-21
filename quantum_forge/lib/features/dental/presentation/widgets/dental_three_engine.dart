// ============================================================================
// DentoLab Three.js Engine — Platform Selector
// ----------------------------------------------------------------------------
// Swapped per platform: a stub for non-web environments (such as flutter test)
// and a dart:js_interop implementation for Flutter Web.
// ============================================================================

export 'dental_three_engine_stub.dart'
    if (dart.library.js_interop) 'dental_three_engine_web.dart';
