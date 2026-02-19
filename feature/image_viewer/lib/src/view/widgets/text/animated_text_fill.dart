import 'package:flutter/material.dart';

class AnimatedSubtitleWord extends StatelessWidget {
  const AnimatedSubtitleWord({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.activeColor,
    required this.isActive,
    required this.duration,

  });

  final String text;
  final TextStyle baseStyle;
  final Color activeColor;
  final bool isActive;
  final Duration duration;


  @override
  Widget build(BuildContext context) {
    final baseColor =
        baseStyle.color ?? Theme.of(context).colorScheme.onSurface;
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: 0, end: isActive ? 1 : 0),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final progress = Curves.easeOutCubic.transform(t);
        final fillStop = progress.clamp(0.0, 1.0);
        final edgeStop = (fillStop + 0.001).clamp(0.0, 1.0);
        final fillColor = activeColor.withValues(alpha: 0.28);

        final textColor =
            Color.lerp(baseColor, activeColor, progress) ?? activeColor;
        return Transform.scale(
          scale: 1 + (0.05 * progress),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0, fillStop, edgeStop, 1],
                colors: [
                  isActive ? fillColor : Colors.transparent,
                  isActive ? fillColor : Colors.transparent,
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
              child: Text(
                text,
                style: baseStyle.copyWith(
                  color: textColor,
                  fontWeight: progress > 0.5
                      ? FontWeight.w700
                      : baseStyle.fontWeight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// class AnimatedFillText extends StatefulWidget {
//   const AnimatedFillText({
//     super.key,
//     required this.text,
//     required this.baseStyle,
//     required this.activeColor,
//     required this.isActive,
//     required this.duration,
//   });

//   final String text;
//   final TextStyle baseStyle;
//   final Color activeColor;
//   final bool isActive;
//   final Duration duration;

//   @override
//   State<AnimatedFillText> createState() => _AnimatedFillTextState();
// }

// class _AnimatedFillTextState extends State<AnimatedFillText>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(vsync: this, duration: widget.duration);

//     _animation = Tween<double>(
//       begin: 0.0,
//       end: widget.isActive ? 1.0 : 0.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

//     // Start animation automatically if isActive, else reset to 0
//     if (widget.isActive) {
//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (mounted) _controller.forward();
//       });
//     } else {
//       _controller.value = 0.0;
//     }
//   }

//   @override
//   void didUpdateWidget(covariant AnimatedFillText oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.isActive != widget.isActive) {
//       if (widget.isActive) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final baseColor =
//         widget.baseStyle.color ?? Theme.of(context).colorScheme.onSurface;
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         return ShaderMask(
//           blendMode: BlendMode.srcIn,
//           shaderCallback: (bounds) {
//             return LinearGradient(
//               stops: [0.0, _animation.value, _animation.value, 1.0],
//               colors: [
//                 widget.activeColor,
//                 widget.activeColor,
//                 Color.lerp(baseColor, widget.activeColor, _animation.value) ??
//                     widget.activeColor,
//                 baseColor,
//               ],
//             ).createShader(bounds);
//           },
//           child: Text(widget.text, style: widget.baseStyle),
//         );
//       },
//     );
//   }
// }
