import 'package:flutter/widgets.dart';

/// Lightweight container to maintain API parity and scope bounded layout passes
/// for staggered animation sequences.
class AnimationLimiter extends StatelessWidget {
  final Widget child;

  const AnimationLimiter({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
