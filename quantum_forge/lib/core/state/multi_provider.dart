import 'package:flutter/widgets.dart';

import 'single_child_widget.dart';

/// In-house replacement for [MultiProvider].
///
/// Flattens nested provider declarations into an efficient visual tree hierarchy.
class MultiProvider extends StatelessWidget {
  final List<dynamic> providers;
  final Widget? child;

  const MultiProvider({
    super.key,
    required this.providers,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget tree = child ?? const SizedBox.shrink();
    for (final provider in providers.reversed) {
      if (provider is SingleChildWidget) {
        tree = provider.buildWithChild(context, tree);
      } else if (provider is Widget) {
        tree = provider;
      }
    }
    return tree;
  }
}
