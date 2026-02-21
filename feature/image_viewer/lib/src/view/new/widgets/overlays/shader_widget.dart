import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ShaderWidget extends StatefulWidget {
  final String assetKey;
  final Widget? child;

  const ShaderWidget({super.key, required this.assetKey, this.child});

  @override
  State<ShaderWidget> createState() => _ShaderWidgetState();
}

class _ShaderWidgetState extends State<ShaderWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  FragmentShader? _shader;
  bool _shaderLoadFailed = false;

  late final Ticker _ticker;

  // Using a ValueNotifier allows us to rebuild ONLY the CustomPaint
  // every frame, rather than rebuilding this entire Stateful widget.
  final ValueNotifier<double> _timeNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set up a high-performance ticker
    _ticker = createTicker((Duration elapsed) {
      // Convert elapsed time to seconds for the shader's u_time uniform
      _timeNotifier.value = elapsed.inMicroseconds / 1000000.0;
    });

    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await FragmentProgram.fromAsset(widget.assetKey);
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
        _ticker.start();
      }
    } catch (e) {
      // ADD THIS PRINT STATEMENT
      print('🚨 SHADER FAILED TO LOAD: $e');
      if (mounted) {
        setState(() {
          _shaderLoadFailed = true;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatically pause the shader animation when the app goes
    // into the background to save the user's battery.
    switch (state) {
      case AppLifecycleState.resumed:
        if (_shader != null && !_ticker.isTicking) _ticker.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_ticker.isTicking) _ticker.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shaderLoadFailed || _shader == null) {
      // Return an empty box (or the child) while loading or if it fails
      return widget.child ?? const SizedBox.expand();
    }

    return AnimatedBuilder(
      animation: _timeNotifier,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _GeneralShaderPainter(
            shader: _shader!,
            time: _timeNotifier.value,
          ),
          // We pass the child through so you can wrap this widget around other UI
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GeneralShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;

  _GeneralShaderPainter({required this.shader, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. u_resolution (vec2 takes float slots 0 and 1)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // 2. u_time (float takes slot 2)
    shader.setFloat(2, time);

    final paint = Paint()..shader = shader;

    // Draw the shader across the entire available canvas space
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GeneralShaderPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
