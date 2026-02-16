import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/design_system.dart';
import 'package:design_system/gen/assets.gen.dart';
import 'package:flutter/material.dart';

class CloudLayer extends StatefulWidget {
  final double speedMultiplier;
  final double opacity;
  final double height;
  final Widget cloudImage;
 

  const CloudLayer({
    required this.speedMultiplier,
    required this.opacity,
    required this.height,
    required this.cloudImage,
    Key? key,
  }) : super(key: key);

  @override
  _CloudLayerState createState() => _CloudLayerState();
}

class _CloudLayerState extends State<CloudLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (20 / widget.speedMultiplier).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final left = (_controller.value * (screenWidth + 300)) - 300;
        return Positioned(
          left: left,
          top: widget.height,
          child: Opacity(opacity: widget.opacity, child: widget.cloudImage),
        );
      },
    );
  }
}

class ParallaxClouds extends StatelessWidget {
  const ParallaxClouds({Key? key, required this.visible}) : super(key: key);

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final Color cloudColor = Theme.of(context).colorScheme.surface.withValues(alpha: 0.6);
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        height: 400,
        width: double.infinity,
        child: DelayedDisplay(
          child: Stack(
            children: [
              CloudLayer(
                speedMultiplier: 0.4,
                opacity: 0.3,
                height: 10,
                cloudImage: Assets.graphics.cloudWhite
                    .designImage(width: 50, color: cloudColor),
              ),
              CloudLayer(
                speedMultiplier: 0.4,
                opacity: 0.3,
                height: 20,
                cloudImage: Assets.graphics.cloudWhite
                    .designImage(width: 100, color: cloudColor),
              ),
              // Middle Layer
              CloudLayer(
                speedMultiplier: 0.7,
                opacity: 0.6,
                height: 100,
                cloudImage: Assets.graphics.cloudWhite
                    .designImage(width: 180, color: cloudColor),
              ),
              // Foreground Layer (Fastest, fully opaque, lowest down)
              CloudLayer(
                speedMultiplier: 1.2,
                opacity: 1.0,
                height: 220,
                cloudImage: Assets.graphics.cloudWhite
                    .designImage(width: 250, color: cloudColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
