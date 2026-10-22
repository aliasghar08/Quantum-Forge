import 'package:flutter/widgets.dart';

/// Low-level [InheritedNotifier] carrying a [Listenable] of type [T].
///
/// When the underlying [notifier] triggers `notifyListeners()`, any context
/// that subscribed to this scope is automatically scheduled for rebuild.
class InheritedNotifierScope<T> extends InheritedNotifier<Listenable> {
  final T value;

  const InheritedNotifierScope({
    super.key,
    required Listenable notifier,
    required this.value,
    required super.child,
  }) : super(notifier: notifier);
}
