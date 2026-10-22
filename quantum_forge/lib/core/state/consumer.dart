import 'package:flutter/widgets.dart';

import 'provider_resolver.dart';

/// In-house replacement for [Consumer].
///
/// Obtains a [T] from its nearest ancestor and passes it to the [builder].
class Consumer<T> extends StatelessWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const Consumer({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      QuantumProvider.of<T>(context, listen: true),
      child,
    );
  }
}

/// In-house replacement for [Consumer2].
///
/// Obtains [A] and [B] from their nearest ancestors and passes them to the [builder].
class Consumer2<A, B> extends StatelessWidget {
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
  final Widget? child;

  const Consumer2({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      QuantumProvider.of<A>(context, listen: true),
      QuantumProvider.of<B>(context, listen: true),
      child,
    );
  }
}

/// In-house replacement for [Consumer3].
///
/// Obtains [A], [B], and [C] from their nearest ancestors and passes them to the [builder].
class Consumer3<A, B, C> extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    A a,
    B b,
    C c,
    Widget? child,
  ) builder;
  final Widget? child;

  const Consumer3({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      QuantumProvider.of<A>(context, listen: true),
      QuantumProvider.of<B>(context, listen: true),
      QuantumProvider.of<C>(context, listen: true),
      child,
    );
  }
}
