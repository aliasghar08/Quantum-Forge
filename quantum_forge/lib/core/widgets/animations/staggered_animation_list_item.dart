import 'package:flutter/material.dart';

export 'animation_limiter.dart';
export 'package:quantum_forge/core/animations/fade_in_slide_animation.dart';

/// Pure Flutter self-contained staggered animation item replacing flutter_staggered_animations.
class StaggeredAnimationListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final double verticalOffset;
  final int delayStepMs;

  const StaggeredAnimationListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.verticalOffset = 30.0,
    this.delayStepMs = 40,
  });

  @override
  State<StaggeredAnimationListItem> createState() =>
      _StaggeredAnimationListItemState();
}

class _StaggeredAnimationListItemState extends State<StaggeredAnimationListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, widget.verticalOffset / 100.0),
      end: Offset.zero,
    ).animate(curved);

    final delay = Duration(
      milliseconds: widget.index.clamp(0, 15) * widget.delayStepMs,
    );
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
