// ============================================================================
// CardioCath Three.js Engine — Platform Selector
// ----------------------------------------------------------------------------
// Swapped per platform: a stub for non-web environments (such as flutter test)
// and a dart:js_interop implementation for Flutter Web.
// ============================================================================

export 'cardiac_three_engine_stub.dart'
    if (dart.library.js_interop) 'cardiac_three_engine_web.dart';

