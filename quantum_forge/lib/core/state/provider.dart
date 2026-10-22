import 'package:flutter/widgets.dart';

import 'inherited_provider_scope.dart';
import 'provider_resolver.dart';
import 'provider_types.dart';
import 'single_child_widget.dart';

/// In-house replacement for [Provider].
///
/// Exposes a value of type [T] to the descendant widget tree.
class Provider<T> extends StatelessWidget implements SingleChildWidget {
  final Create<T>? create;
  final T? value;
  final Dispose<T>? dispose;
  final Widget? child;

  const Provider({
    super.key,
    required this.create,
    this.dispose,
    this.child,
  }) : value = null;

  const Provider.value({
    super.key,
    required this.value,
    this.child,
  })  : create = null,
        dispose = null;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    final createFn = create;
    if (createFn != null) {
      return ProviderWithCreate<T>(
        key: key,
        create: createFn,
        dispose: dispose,
        child: child,
      );
    }
    return ProviderWithValue<T>(
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

/// Reusable stateful container that handles creation and lifecycle disposal of [T].
class ProviderWithCreate<T> extends StatefulWidget {
  final Create<T> create;
  final Dispose<T>? dispose;
  final Widget? child;

  const ProviderWithCreate({
    super.key,
    required this.create,
    this.dispose,
    this.child,
  });

  @override
  State<ProviderWithCreate<T>> createState() => _ProviderWithCreateState<T>();
}

class _ProviderWithCreateState<T> extends State<ProviderWithCreate<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.create(context);
  }

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose!(context, _value);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedProviderScope<T>(
      value: _value,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

/// Reusable stateless container that binds an already instantiated value [T].
class ProviderWithValue<T> extends StatelessWidget {
  final T value;
  final Widget? child;

  const ProviderWithValue({
    super.key,
    required this.value,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InheritedProviderScope<T>(
      value: value,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
