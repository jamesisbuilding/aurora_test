import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/new/pages/details_page.dart';
import 'package:image_viewer/src/view/new/widgets/painters/circle_painter.dart';
import 'package:image_viewer/src/view/new/widgets/text/cryptic_text.dart';

const _targetDiff = 300.0;
const _diffBuffer = 50;

class ImagePage extends StatefulWidget {
  final ImageModel image;
  const ImagePage({super.key, required this.image});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;

  double? _startLocation;
  bool _isNavigating = false; // Prevents pushing the route multiple times

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      // Shorten duration for when it reverses back to 0 upon letting go
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _startLocation = details.globalPosition.dy;
  }

  void _handleSwipeUp(DragUpdateDetails details) {
    // Stop processing if we don't have a start point or are already navigating
    if (_startLocation == null || _isNavigating) return;

    double diff = _startLocation! - details.globalPosition.dy;

    // Calculate percentage and strictly update the animation value
    double diffPerc = (diff / _targetDiff).clamp(0.0, 1.0);
    _animationController.value = diffPerc;

    if (diff > _targetDiff + _diffBuffer) {
      _isNavigating = true;
      HapticFeedback.heavyImpact();

      Navigator.of(context)
          .push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return DetailsPage(image: widget.image);
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
            // Reset everything when the user pops back to this page
            _isNavigating = false;
            _startLocation = null;
            _animationController.value = 0.0;
          });
    }
  }

  void _resetPointer() {
    _startLocation = null;
    if (mounted && !_isNavigating) {
      // Smoothly animate back to 0 if the user didn't swipe far enough
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleSwipeUp,
      onVerticalDragEnd: (_) => _resetPointer(),
      onVerticalDragCancel: () => _resetPointer(),
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: ValueKey('details_${widget.image.uid}'),
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  child: CachedImage(fit: BoxFit.cover, url: widget.image.url),
                ),
              ),
            ),
            Positioned(
              bottom: -250,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animation.value * _animation.value,
                    // FIXED: Replaced the Container with a CustomPaint widget
                    child: CustomPaint(
                      size: const Size(500, 500),
                      painter: CirclePainter(
                        color: widget.image.lightestColor.withValues(
                          alpha: _animation.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 70,
              child: Column(
                spacing: 0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    width: MediaQuery.sizeOf(context).width * 0.7,
                    child: CryptoText(
                      widget.image.title,
                      style: TextStyle(
                        fontSize: 32,
                        letterSpacing: -4,
                        color: widget.image.lightestColor,
                      ),
                    ),
                  ),

                  DelayedDisplay(
                    delay: const Duration(seconds: 2),
                    slidingBeginOffset: const Offset(0, 0),
                    child: SizedBox(
                      height: 100,
                      width: MediaQuery.sizeOf(context).width * 0.45,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          widget.image.description,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: -1,
                            foreground: Paint()
                              ..blendMode = BlendMode.difference
                              ..color = widget.image.lightestColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              child: DelayedDisplay(
                delay: const Duration(seconds: 3),
                child: Assets.gifs.arrowDown.designImage(
                  height: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
