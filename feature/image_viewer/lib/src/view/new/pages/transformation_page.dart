import 'dart:math' as math;
import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/new/pages/color_page.dart';
import 'package:image_viewer/src/view/new/widgets/overlays/shader_widget.dart';
import 'package:image_viewer/src/view/new/widgets/painters/circle_painter.dart';
import 'package:image_viewer/src/view/widgets/background/image_viewer_background.dart';

class TransformationPage extends StatefulWidget {
  final ImageModel image;
  const TransformationPage({super.key, required this.image});

  @override
  State<TransformationPage> createState() => _TransformationPageState();
}

class _TransformationPageState extends State<TransformationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _navingOut = false;

  late String image1;
  late String image2;
  late String image3;
  late String image4;

  late AnimationController _circleController;
  late Animation _circleAnimation;

  // Track the flip state for each of the 4 cards to prevent repeated haptics
  final Set<int> _flippedIndices = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_listenToScroll);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    );
    _circleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_circleController);

    if (widget.image.url ==
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d') {
      image1 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/nike%2Fp1.png?alt=media';
      image2 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/nike%2Fp2.png?alt=media';
      image3 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/nike%2Fp3.png?alt=media';
      image4 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/nike%2Fp4.png?alt=media';
    } else if (widget.image.url ==
        'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa') {
      image1 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/space%2Fp1.png?alt=media';
      image2 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/space%2Fp2.png?alt=media';
      image3 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/space%2Fp3.png?alt=media';
      image4 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/space%2Fp4.png?alt=media';
    } else if (widget.image.url ==
        'https://images.unsplash.com/photo-1519681393784-d120267933ba') {
      image1 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/mountain%2Fp1.png?alt=media';
      image2 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/mountain%2Fp2.png?alt=media';
      image3 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/mountain%2Fp3.png?alt=media';
      image4 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/mountain%2Fp4.png?alt=media';
    } else if (widget.image.url ==
        'https://images.unsplash.com/photo-1501785888041-af3ef285b470') {
      image1 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/lake%2Fp1.png?alt=media';
      image2 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/lake%2Fp2.png?alt=media';
      image3 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/lake%2Fp3.png?alt=media';
      image4 =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/lake%2Fp4.png?alt=media';
    } else {
      image1 = widget.image.url;
      image2 = widget.image.url;
      image3 = widget.image.url;
      image4 = widget.image.url;
    }
  }

  void _navigateOutIfNeeded() {
    _navingOut = true;
    Navigator.of(context).pop();
  }

  void _navigateNextIfNeeded() {
    _navingOut = true;
    HapticFeedback.heavyImpact();
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return ColorPage(image: widget.image);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
          ),
        )
        .then((_) {
          _navingOut = false;
        });
  }

  // Logic to handle single haptic triggers when cards cross the flip threshold
  void _checkCardHaptic(int index, double p) {
    const double threshold = 0.65;
    bool pastThreshold = p >= threshold;

    if (pastThreshold && !_flippedIndices.contains(index)) {
      _flippedIndices.add(index);
      HapticFeedback.heavyImpact();
    } else if (!pastThreshold && _flippedIndices.contains(index)) {
      _flippedIndices.remove(index);
      HapticFeedback.lightImpact();
    }
  }

  void _listenToScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.offset < -100 && !_navingOut) {
      _navigateOutIfNeeded();
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (maxScroll > 0) {
      double diff = (currentScroll / maxScroll).clamp(0.0, 1.0);
      _animationController.value = diff;

      // Check haptics for each card segment based on the scroll progress
      _checkCardHaptic(0, ((diff - 0.00) / 0.1).clamp(0.0, 1.0));
      _checkCardHaptic(1, ((diff - 0.25) / 0.1).clamp(0.0, 1.0));
      _checkCardHaptic(2, ((diff - 0.50) / 0.1).clamp(0.0, 1.0));
      _checkCardHaptic(3, ((diff - 0.75) / 0.1).clamp(0.0, 1.0));
    }

    if (_circleAnimation.value > 0 && (_scrollController.offset < maxScroll)) {
      _circleController.animateTo(0);
    }

    if (_scrollController.offset > maxScroll) {
      double absoluteScroll = _scrollController.offset / maxScroll;
      double overPerc = 0;

      if (absoluteScroll > 1) {
        overPerc = ((absoluteScroll - 1) / 0.06).clamp(0, 1);
        _circleController.value = overPerc;
      }

      if (absoluteScroll >= 1.1 && !_navingOut) {
        _navigateNextIfNeeded();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  Widget _buildFlippingCard({
    required double p,
    required double rotX,
    required double baseRotY,
    required String imageUrl,
    Key? heroTag,
  }) {
    final bool isFront = p < 0.65;

    Widget cardContent = isFront
        ? RepaintBoundary(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                  width: 275,
                  height: 366,
                  decoration: BoxDecoration(
                    color: widget.image.darkestColor, 
                    border: Border.all(color: widget.image.lightestColor),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: p > 0
                        ? AnimatedBackground(
                            key: const ValueKey('bg'),
                            imageColors: widget.image.colorPalette,
                          )
                        : const SizedBox(
                            key: ValueKey('empty'),
                          ),
                  ),
                ),
            ),
          ),
        )
        : Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(math.pi),
            child: Container(
              width: 275,
              height: 366,
              decoration: BoxDecoration(
                border: Border.all(color: widget.image.lightestColor),
              ),
              child: CachedImage(fit: BoxFit.cover, url: imageUrl),
            ),
          );

    Widget transformedCard = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateX(rotX)
        ..rotateY(baseRotY - (p * math.pi)),
      child: cardContent,
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag,
        child: Center(child: transformedCard),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: transformedCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.sizeOf(context).height,
            width: MediaQuery.sizeOf(context).width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [widget.image.darkestColor, widget.image.darkestColor],
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.sizeOf(context).height,
            width: MediaQuery.sizeOf(context).width,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final screenHeight = MediaQuery.sizeOf(context).height;
                final screenWidth = MediaQuery.sizeOf(context).width;
                final progress = _animationController.value;

                double p1 = ((progress - 0.00) / 0.1).clamp(0.0, 1.0);
                double p2 = ((progress - 0.15) / 0.1).clamp(0.0, 1.0);
                double p3 = ((progress - 0.45) / 0.1).clamp(0.0, 1.0);
                double p4 = ((progress - 0.7) / 0.1).clamp(0.0, 1.0);

                final double baseRotX = 0 * math.pi / 180;
                final double baseRotY = 25 * math.pi / 180;

                print(progress);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: Opacity(
                            opacity: 0.1,
                            child: ShaderWidget(
                              assetKey:
                                  'packages/image_viewer/shaders/transparent_grain.frag',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.2),
                          _buildFlippingCard(
                            p: p1,
                            rotX: -baseRotX,
                            baseRotY: baseRotY,
                            imageUrl: image1,
                            heroTag: ValueKey('details_${widget.image.uid}'),
                          ),

                          _buildFlippingCard(
                            p: p2,
                            rotX: baseRotX,
                            baseRotY: baseRotY,
                            imageUrl: image2,
                          ),

                          _buildFlippingCard(
                            p: p3,
                            rotX: -baseRotX,
                            baseRotY: baseRotY,
                            imageUrl: image3,
                          ),

                          _buildFlippingCard(
                            p: p4,
                            rotX: baseRotX,
                            baseRotY: baseRotY,
                            imageUrl: image4,
                          ),
                          SizedBox(
                            height: screenHeight * 0.5,
                            width: 300,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 100.0),
                              child: Text(
                                widget.image.description2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  height: 1.1,
                                  foreground: Paint()
                                    ..blendMode = BlendMode.difference
                                    ..color = Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        height: progress * screenHeight,
                        width: 1,
                        color: widget.image.lightestColor,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        height: progress * screenHeight,
                        width: 1,
                        color: widget.image.lightestColor,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        height: 1,
                        width: progress * screenWidth,

                        color: widget.image.lightestColor,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        width: progress * screenWidth,
                        color: widget.image.lightestColor,
                      ),
                    ),
                    Positioned(
                      bottom: -150,
                      child: AnimatedBuilder(
                        animation: _circleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _circleAnimation
                                .value, // Increased multiplier to fill screen
                            child: CustomPaint(
                              size: const Size(300, 300),
                              painter: CirclePainter(
                                borderColor: widget.image.lightestColor,
                                borderWidth: 1,
                                color: widget.image.darkestColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: progress > 0.9 ? 1 : 0,
                        child: Assets.gifs.arrowDown.designImage(
                          height: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
