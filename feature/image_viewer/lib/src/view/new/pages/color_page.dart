import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/new/pages/cta_page.dart';
import 'package:image_viewer/src/view/new/widgets/overlays/shader_widget.dart';
import 'package:image_viewer/src/view/new/widgets/painters/circle_painter.dart';
import 'package:image_viewer/src/view/widgets/background/image_viewer_background.dart';

class ColorPage extends StatefulWidget {
  final ImageModel image;
  const ColorPage({super.key, required this.image});

  @override
  State<ColorPage> createState() => _ColorPageState();
}

class _ColorPageState extends State<ColorPage> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _colorBoxController;
  late AnimationController _circleController;
  int _colorIndex = 0;
  bool _navingOut = false;
  bool _poppingOut = false;

  @override
  void initState() {
    super.initState();
    _colorBoxController = AnimationController(vsync: this);
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_listenToCircle);
    _pageController = PageController()..addListener(_listenToScroll);
  }

  _listenToCircle() async {
    if (_circleController.value > 0 && _circleController.value < 0.9 && !_navingOut) {
      print(_circleController.value);
      HapticFeedback.lightImpact();
      await Future.delayed(
        Duration(milliseconds: ((1 - _circleController.value) * 100).round()),
      );
    }
  }

  void _navigateNextIfNeeded() async {
    if (_navingOut) return;
    _navingOut = true;

    HapticFeedback.heavyImpact();
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CTAPage(image: widget.image),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        )
        .then((_) => _navingOut = false);
  }

  void _navigateBackIfNeeded() {
    // 1. If we are already popping, kill the execution immediately.
    if (_poppingOut) return;

    // 2. Lock it permanently for this lifecycle.
    _poppingOut = true;

    if (mounted) {
      HapticFeedback.mediumImpact();
      // Use maybePop to ensure we don't pop the root route by accident
      Navigator.of(context).maybePop();

      // Removed the .then() reset. We want _poppingOut to stay TRUE
      // until the class is disposed to prevent double-firing.
    }
  }

  void _listenToScroll() {
    if (!_pageController.hasClients) return;

    final pixels = _pageController.position.pixels;
    final maxScroll = _pageController.position.maxScrollExtent;
    final ratio = maxScroll != 0 ? (pixels / maxScroll) : 0.0;

    double clampedRatio = ratio.clamp(0.0, 1.0);
    _colorBoxController.value = clampedRatio;

    // Logic for which box is currently "active"
    int newIndex = (clampedRatio * 4).floor().clamp(0, 4);
    if (newIndex != _colorIndex) {
      setState(() => _colorIndex = newIndex);
    }

    // --- NAVIGATION LOGIC ---

    // Navigate back if we scroll up hard from the top
    // Guarantee single pop only by checking _poppingOut AGAIN
    if (pixels < -100 && !_poppingOut) {
      _navigateBackIfNeeded();
    }

    // If we are overscrolling at the end of the list
    if (pixels > maxScroll) {
      double overscrollAmount = pixels - maxScroll;
      // Map 150px of overscroll to the 0.0 -> 1.0 circle animation
      double overPerc = (overscrollAmount / 150).clamp(0.0, 1.0);
      _circleController.value = overPerc;

      if (overPerc >= 1.0) {
        _navigateNextIfNeeded();
      }
    } else {
      _circleController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _colorBoxController.dispose();
    _circleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Background stays fixed
          Positioned.fill(
            child: AnimatedBackground(imageColors: widget.image.colorPalette),
          ),

          // 2. Grain Shader
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Opacity(
                  opacity: 0.2,
                  child: ShaderWidget(
                    assetKey:
                        'packages/image_viewer/shaders/transparent_grain.frag',
                  ),
                ),
              ),
            ),
          ),

          // 3. YOUR ORIGINAL WIDGET CONFIGURATION
          SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: -150,
                  child: AnimatedBuilder(
                    animation: _circleController,
                    builder: (context, child) {
                      return Transform.scale(
                        // Exponential scale for a snappier fill
                        scale:
                            _circleController.value *
                            _circleController.value *
                            8,
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: CirclePainter(
                            color: widget.image.darkestColor.withValues(
                              alpha: _circleController.value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AnimatedBuilder(
                  animation: _colorBoxController,
                  builder: (context, child) {
                    final double value = _colorBoxController.value;
                    final double pageProgress = value * 4;
                    final int currentIndex = pageProgress.floor().clamp(0, 4);
                    final double localProgress = pageProgress - currentIndex;
                    final double ratio = (localProgress / 0.4).clamp(0.0, 1.0);

                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(5, (index) {
                        if (index < currentIndex) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: SizedBox(height: 50, width: 50),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              index == currentIndex
                                  ? ratio * -MediaQuery.sizeOf(context).height
                                  : 0,
                            ),

                            child: index == widget.image.colorPalette.length - 1
                                ? Hero(
                                    tag: 'color_key',
                                    child: Transform.scale(
                                      scale:
                                          (1 + (1 * _circleController.value)),
                                      child: Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          color:
                                              widget.image.colorPalette[index],
                                          border: Border.all(
                                            color: widget.image.lightestColor.withValues(alpha: _circleController.value,)
                                          )
                                        ),
                                        child: Opacity(
                                          opacity: _circleController.value,
                                          child: CachedImage(
                                            url: widget.image.url,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 50,
                                    width: 50,

                                    decoration: BoxDecoration(
                                      color: widget.image.colorPalette[index],
                                    ),
                                  ),
                          ),
                        );
                      }),
                    );
                  },
                ),

                // The Inner PageView (The Text)
                Positioned.fill(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) async {
                      for (int i = 0; i <= index; i++) {
                        HapticFeedback.lightImpact();
                        await Future.delayed(
                          Duration(milliseconds: 10 * index),
                        );
                      }
                    },
                    scrollDirection: Axis.vertical,
                    // Use BouncingScrollPhysics so we can detect pixels > maxScrollExtent
                    physics: const BouncingScrollPhysics(),
                    children: List.generate(
                      5,
                      (index) => Align(
                        alignment: index % 2 == 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: SizedBox(
                          height: 5 * 62,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: List.generate(5, (colIndex) {
                              String sentence = '';
                              // Repeat for all up to 5
                              if (colIndex == 0) {
                                sentence = widget.image.hypeBuildingTagline1;
                              } else if (colIndex == 1) {
                                sentence = widget.image.hypeBuildingTagline2;
                              } else if (colIndex == 2) {
                                sentence = widget.image.hypeBuildingTagline3;
                              } else if (colIndex == 3) {
                                sentence = widget.image.hypeBuildingTagline4;
                              } else if (colIndex == 4) {
                                sentence = widget.image.hypeBuildingTagline5;
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Container(
                                  height: 50,
                                  width: 200,
                                  color: index == colIndex
                                      ? widget.image.colorPalette[index]
                                            .withValues(alpha: 0)
                                      : Colors.transparent,

                                  child: index == colIndex
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                            // horizontal: 20.0,
                                          ),
                                          child: Center(
                                            child: Text(
                                              sentence,

                                              style: TextStyle(
                                                letterSpacing: -0.5,
                                                // color: widget
                                                //     .image
                                                //     .colorPalette[index],
                                                foreground: Paint()
                                                  ..color = Colors.white
                                                  ..blendMode =
                                                      BlendMode.difference,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(width: 200, height: 50),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
