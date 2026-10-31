import 'package:flutter/material.dart';

/// Pure in-house animation replacing `flutter_staggered_animations` package.
///
/// Combines [SlideTransition] and [FadeTransition] driven by an [AnimationController]
/// with configurable curves, offsets, delays, and duration.
class FadeInSlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset initialOffset;
  final Curve curve;
  final int index;
  final int delayStepMs;

  const FadeInSlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.initialOffset = const Offset(0.0, 0.2),
    this.curve = Curves.easeOutCubic,
    this.index = 0,
    this.delayStepMs = 0,
  });

  @override
  State<FadeInSlideAnimation> createState() => _FadeInSlideAnimationState();
}

class _FadeInSlideAnimationState extends State<FadeInSlideAnimation>
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
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: widget.initialOffset,
      end: Offset.zero,
    ).animate(curved);

    final totalDelay = widget.delay +
        Duration(milliseconds: widget.index.clamp(0, 20) * widget.delayStepMs);

    if (totalDelay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(totalDelay, () {
        if (mounted) {
          _controller.forward();
        }
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

