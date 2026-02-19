import 'package:flutter/material.dart';

class ScrollDrivenIntroHeader extends SliverPersistentHeaderDelegate {
  ScrollDrivenIntroHeader({
    required this.viewportHeight,
    required this.consumeDistance,
    required this.childBuilder,
  });

  final double viewportHeight;
  final double consumeDistance;
  final Widget Function(double progress) childBuilder;

  @override
  double get maxExtent => viewportHeight;

  @override
  double get minExtent =>
      (viewportHeight - consumeDistance).clamp(0.0, viewportHeight);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final total = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final progress = (shrinkOffset / total).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: 1 - (0.15 * progress),
          child: childBuilder(progress),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant ScrollDrivenIntroHeader oldDelegate) =>
      oldDelegate.viewportHeight != viewportHeight ||
      oldDelegate.consumeDistance != consumeDistance;
}
