import 'package:flutter/material.dart';

/// Animated wave background with two waves (horizontal drift only).
/// Pass [visible] when expanded; [color1] and [color2] for wave colors (e.g. from image palette).
class WaveBg extends StatefulWidget {
  const WaveBg({
    super.key,
    this.visible = false,
    this.color1,
    this.color2,
  });

  final bool visible;
  final Color? color1;
  final Color? color2;

  @override
  State<WaveBg> createState() => _WaveBgState();
}

class _WaveBgState extends State<WaveBg> with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    animation = Tween<double>(begin: -500, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _WaveClipPath(
      animation: animation,
      visible: widget.visible,
      color1: widget.color1,
      color2: widget.color2,
    );
  }
}

class _WaveClipPath extends StatelessWidget {
  const _WaveClipPath({
    required this.animation,
    required this.visible,
    this.color1,
    this.color2,
  });

  final Animation<double> animation;
  final bool visible;
  final Color? color1;
  final Color? color2;

  static const _waveHeight = 200.0;
  static const _wave1FinalBottom = 50.0;
  static const _wave2FinalBottom = 0.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final theme = Theme.of(context);
        final light = color1 ?? theme.colorScheme.primary;
        final dark = color2 ?? theme.colorScheme.primary;
        final wave1Bottom = visible ? _wave1FinalBottom : -_waveHeight - 50;
        final wave2Bottom = visible ? _wave2FinalBottom : -_waveHeight - 50;
        return Column(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: wave1Bottom,
                    right: animation.value,
                    child: ClipPath(
                      clipper: _BottomWaveClipper(),
                      child: Container(
                          color: dark, width: 2000, height: _waveHeight),
                    ),
                  ),
                  Positioned(
                    bottom: wave2Bottom,
                    left: animation.value,
                    child: ClipPath(
                      clipper: _BottomWaveClipper(),
                      child: Opacity(
                        opacity: 0.5,
                        child: Container(
                            color: light, width: 2000, height: _waveHeight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    path.lineTo(0.0, 40.0);
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 40.0);

    for (int i = 0; i < 10; i++) {
      if (i % 2 == 0) {
        path.quadraticBezierTo(
          size.width - (size.width / 16) - (i * size.width / 8),
          0.0,
          size.width - ((i + 1) * size.width / 8),
          size.height - 160,
        );
      } else {
        path.quadraticBezierTo(
          size.width - (size.width / 16) - (i * size.width / 8),
          size.height - 120,
          size.width - ((i + 1) * size.width / 8),
          size.height - 160,
        );
      }
    }

    path.lineTo(0.0, 40.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
