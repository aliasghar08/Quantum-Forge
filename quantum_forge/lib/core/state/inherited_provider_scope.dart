import 'package:flutter/widgets.dart';

/// Low-level [InheritedWidget] carrying a non-Listenable value of type [T].
class InheritedProviderScope<T> extends InheritedWidget {
  final T value;

  const InheritedProviderScope({
    super.key,
    required this.value,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant InheritedProviderScope<T> oldWidget) {
    return value != oldWidget.value;
  }
}
