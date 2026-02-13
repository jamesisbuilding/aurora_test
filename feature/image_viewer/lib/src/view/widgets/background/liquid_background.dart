import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LiquidBackgroundPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final List<Color> colors; // Your list of 5 colors

  LiquidBackgroundPainter({
    required this.shader,
    required this.time,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. iResolution (vec2)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // 2. iTime (float)
    shader.setFloat(2, time);

    // 3. Colors (Each vec3 takes 3 slots)
    // We map 4 colors from your list of 5 to the shader uniforms
    for (int i = 0; i < 4; i++) {
      final color = colors[i];
      final int baseIndex = 3 + (i * 3); // Start at index 3
      shader.setFloat(baseIndex, color.r);
      shader.setFloat(baseIndex + 1, color.g);
      shader.setFloat(baseIndex + 2, color.b);
    }

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidBackgroundPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.colors != colors;
}

class LiquidBackground extends StatefulWidget {
  final List<Color>? colors;
  final ValueListenable<List<Color>>? colorsListenable;

  const LiquidBackground({
    super.key,
    this.colors,
    this.colorsListenable,
  }) : assert(
         (colors != null) != (colorsListenable != null),
         'Provide exactly one of colors or colorsListenable',
       );

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

const _colorTransitionDuration = Duration(milliseconds: 150);
const _minShaderColors = 4;

List<Color> _padColors(List<Color> colors) {
  if (colors.length >= _minShaderColors) return colors;
  final out = List<Color>.from(colors);
  while (out.length < _minShaderColors) {
    out.add(out.isEmpty ? const Color(0xFF6B4E9D) : out[out.length % colors.length]);
  }
  return out;
}

List<Color> _lerpColors(List<Color> from, List<Color> to, double t) {
  final a = _padColors(from);
  final b = _padColors(to);
  final len = math.max(a.length, b.length);
  return List.generate(len, (i) {
    final cA = a[i.clamp(0, a.length - 1)];
    final cB = b[i.clamp(0, b.length - 1)];
    return Color.lerp(cA, cB, t)!;
  });
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with TickerProviderStateMixin {
  FragmentShader? _shader;
  late AnimationController _timeController;
  late AnimationController _colorTransitionController;
  List<Color> _displayedColors = const [];
  List<Color> _transitionFromColors = const [];
  List<Color> _transitionToColors = const [];
  VoidCallback? _listenerRemove;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _colorTransitionController = AnimationController(
      vsync: this,
      duration: _colorTransitionDuration,
    );
    _colorTransitionController.addListener(_onColorTransitionTick);
    _subscribeToListenable();
  }

  void _subscribeToListenable() {
    final listenable = widget.colorsListenable;
    if (listenable != null) {
      void onChanged() {
        final newColors = _padColors(listenable.value);
        _onTargetColorsChanged(newColors);
      }
      listenable.addListener(onChanged);
      _listenerRemove = () => listenable.removeListener(onChanged);
      onChanged();
    }
  }

  void _onTargetColorsChanged(List<Color> target) {
    final padded = _padColors(target);
    if (_displayedColors.isEmpty) {
      _displayedColors = padded;
      if (mounted) setState(() {});
      return;
    }
    _transitionFromColors = List.of(_displayedColors);
    _transitionToColors = padded;
    _colorTransitionController.forward(from: 0);
  }

  void _onColorTransitionTick() {
    if (!mounted) return;
    final t = Curves.easeInOutCubic.transform(_colorTransitionController.value);
    setState(() {
      _displayedColors = _lerpColors(_transitionFromColors, _transitionToColors, t);
    });
  }

  Future<void> _loadShader() async {
    const assetKey = 'packages/image_viewer/shaders/gradient.frag';
    final program = await FragmentProgram.fromAsset(assetKey);
    if (mounted) setState(() => _shader = program.fragmentShader());
  }

  @override
  void didUpdateWidget(covariant LiquidBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.colorsListenable != widget.colorsListenable) {
      _listenerRemove?.call();
      _listenerRemove = null;
      _subscribeToListenable();
    }
  }

  @override
  void dispose() {
    _listenerRemove?.call();
    _colorTransitionController.removeListener(_onColorTransitionTick);
    _timeController.dispose();
    _colorTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) return const SizedBox.expand();

    final colors = widget.colorsListenable != null
        ? _displayedColors
        : _padColors(widget.colors ?? const []);

    return _buildPainter(colors);
  }

  Widget _buildPainter(List<Color> colors) {
    return AnimatedBuilder(
      animation: Listenable.merge([_timeController, _colorTransitionController]),
      builder: (context, _) {
        final displayColors = widget.colorsListenable != null
            ? _displayedColors
            : _padColors(colors);
        return CustomPaint(
          size: Size.infinite,
          painter: LiquidBackgroundPainter(
            shader: _shader!,
            time: _timeController.value * 10,
            colors: displayColors,
          ),
        );
      },
    );
  }
}
