import 'package:flutter/widgets.dart';

import 'inherited_notifier_scope.dart';
import 'provider_resolver.dart';
import 'provider_types.dart';
import 'single_child_widget.dart';

/// In-house replacement for [ChangeNotifierProvider].
///
/// Exposes a [Listenable] of type [T] to the descendant widget tree and
/// rebuilds dependents when [notifyListeners] is invoked.
class ChangeNotifierProvider<T extends Listenable> extends StatelessWidget
    implements SingleChildWidget {
  final Create<T>? create;
  final T? value;
  final Widget? child;

  const ChangeNotifierProvider({
    super.key,
    required this.create,
    this.child,
  }) : value = null;

  const ChangeNotifierProvider.value({
    super.key,
    required this.value,
    this.child,
  }) : create = null;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    final createFn = create;
    if (createFn != null) {
      return ChangeNotifierWithCreate<T>(
        key: key,
        create: createFn,
        child: child,
      );
    }
    return ChangeNotifierWithValue<T>(
      key: key,
      value: value as T,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildWithChild(context, child);
  }

  static T of<T>(BuildContext context, {bool listen = true}) {
    return QuantumProvider.of<T>(context, listen: listen);
  }
}

/// Reusable stateful container managing instantiation and disposal of a [Listenable].
class ChangeNotifierWithCreate<T extends Listenable> extends StatefulWidget {
  final Create<T> create;
  final Widget? child;

  const ChangeNotifierWithCreate({
    super.key,
    required this.create,
    this.child,
  });

  @override
  State<ChangeNotifierWithCreate<T>> createState() =>
      _ChangeNotifierWithCreateState<T>();
}

class _ChangeNotifierWithCreateState<T extends Listenable>
    extends State<ChangeNotifierWithCreate<T>> {
  late T _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = widget.create(context);
  }

  @override
  void dispose() {
    if (_notifier is ChangeNotifier) {
      (_notifier as ChangeNotifier).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedNotifierScope<T>(
      notifier: _notifier,
      value: _notifier,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

/// Reusable stateless container providing an existing [Listenable] instance without auto-disposal.
class ChangeNotifierWithValue<T extends Listenable> extends StatelessWidget {
  final T value;
  final Widget? child;

  const ChangeNotifierWithValue({
    super.key,
    required this.value,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InheritedNotifierScope<T>(
      notifier: value,
      value: value,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
