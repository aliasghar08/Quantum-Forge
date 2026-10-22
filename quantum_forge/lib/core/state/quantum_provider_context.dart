import 'package:flutter/widgets.dart';

import 'provider_resolver.dart';

/// Extension methods on [BuildContext] providing [read], [watch], and [select].
extension QuantumProviderContext on BuildContext {
  /// Reads a value of type [T] without establishing an active rebuild subscription.
  T read<T>() => QuantumProvider.of<T>(this, listen: false);

  /// Watches a value of type [T], scheduling a rebuild whenever [T] emits changes.
  T watch<T>() => QuantumProvider.of<T>(this, listen: true);

  /// Selects a specific slice or property [R] derived from [T].
  R select<T, R>(R Function(T value) selector) {
    final value = watch<T>();
    return selector(value);
  }
}
