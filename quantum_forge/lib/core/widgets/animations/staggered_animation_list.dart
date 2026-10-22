import 'package:flutter/material.dart';
import 'staggered_animation_list_item.dart';

export 'staggered_animation_list_item.dart' show AnimationLimiter, StaggeredAnimationListItem;

/// Pure Flutter self-contained staggered animation list replacing flutter_staggered_animations.
class StaggeredAnimationList extends StatelessWidget {
  final List<Widget> children;
  final Duration duration;
  final double verticalOffset;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 400),
    this.verticalOffset = 30.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          StaggeredAnimationListItem(
            index: i,
            duration: duration,
            verticalOffset: verticalOffset,
            child: children[i],
          ),
      ],
    );
  }
}
