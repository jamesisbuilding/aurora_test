import 'package:cached_network_image/cached_network_image.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/design_system.dart';
import 'package:design_system/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/widgets/magazine/magazine_page.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'dart:math' as math;

const _dragOffsetTarget = 100;
const _dragTargetBuffer = 50;
const _heroImageTagPrefix = 'gallery_hero_';
const _heroTitleTagPrefix = 'magazine_cover_title_';

class MagazineCover extends StatefulWidget {
  final ImageModel image;

  const MagazineCover({super.key, required this.image});

  @override
  State<MagazineCover> createState() => _MagazineCoverState();
}

class _MagazineCoverState extends State<MagazineCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double? startYOffset;
  bool _isNavigating = false;
  bool _showGradients = false;
  int _gradientFadeToken = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animateGradientsIn();
  }

  Future<void> _animateGradientsIn() async {
    final token = ++_gradientFadeToken;
    if (mounted) {
      setState(() => _showGradients = false);
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted || token != _gradientFadeToken) return;
    setState(() => _showGradients = true);
  }

  _onVerticalDrag(DragUpdateDetails details) {
    if (startYOffset == null) {
      startYOffset = details.localPosition.dy;
      print('[COVER]: started at $startYOffset');
    }

    print('[COVER]: diffence: ${startYOffset! - details.localPosition.dy}');

    double diff = startYOffset! - details.localPosition.dy;

    print(diff / _dragOffsetTarget);

    if(diff < - 100){
      Navigator.of(context).pop(); 
      return; 
    }

    final double animAmount = (diff / _dragOffsetTarget).clamp(0.0, 1.0);
    _animationController.animateTo(animAmount);

    if ((diff >= _dragOffsetTarget + _dragTargetBuffer) && !_isNavigating) {
      _isNavigating = true;
      _animationController.value = 0;
      startYOffset = null;
      print('should navigate');
      HapticFeedback.mediumImpact();
      // Navigator.of(context)
      //     .push(
      //       slideUpRoute<void>(
      //         page: _MagazineDetailPage(image: widget.image),
      //         includeFade: true,
      //       ),
      //     )
      //     .then((_) {
      //       if (!mounted) return;
      //       _isNavigating = false;
      //       _resetDrag(animateBack: true);
      //        HapticFeedback.mediumImpact();
      //       _animateGradientsIn();
      //     });
    }
    // _animationController.animateTo(target)
  }

  void _resetDrag({bool animateBack = false}) {
    if (animateBack && _animationController.value < 1) {
      _animationController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    startYOffset = null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onVerticalDragStart: (details) => _onVerticalDrag(details),
      onVerticalDragUpdate: (details) => _onVerticalDrag(details),
      onVerticalDragEnd: (_) => _resetDrag(animateBack: true),
      onVerticalDragCancel: () => _resetDrag(animateBack: true),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: '$_heroImageTagPrefix${widget.image.uid}',
              child: CachedNetworkImage(
                imageUrl: widget.image.url,
                fit: BoxFit.cover,
                height: MediaQuery.sizeOf(context).height,
                width: MediaQuery.sizeOf(context).width,
                placeholder: (context, url) => Shimmer(
                  child: Container(
                    color: Colors.grey[300],
                    height: MediaQuery.sizeOf(context).height,
                    width: MediaQuery.sizeOf(context).width,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black12,
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showGradients ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: DelayedDisplay(
                  slidingBeginOffset: .zero,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 1 - _animation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                end: Alignment.bottomCenter,
                                begin: Alignment.topCenter,
                                colors: [
                                  widget.image.lightestColor,
                                  widget.image.lightestColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.1, 0.3],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 100,
              child: Opacity(
                opacity: 1,
                child: Text(
                  'IMGO COLLECTION',
                  style: TextStyle(
                    fontFamily: FontFamily.raleway,
                    package: 'design_system',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                    foreground: Paint()
                      ..blendMode = BlendMode.difference
                      ..color = widget.image.lightestColor,
                  ),
                ),
              ),
            ),

            // Container(
            //   color: Colors.black.withValues(alpha: 0.2),
            //   height: MediaQuery.sizeOf(context).height,
            //   width: MediaQuery.sizeOf(context).width,
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showGradients ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 1 - _animation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                widget.image.lightestColor,
                                widget.image.lightestColor.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.2, 0.7],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              // top: MediaQuery.sizeOf(context).height / 5,
              child: Opacity(
                opacity: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Text(
                      //   image.title,
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //     height: 0.9,
                      //     fontFamily: FontFamily.yesevaOne,
                      //     package: 'design_system',
                      //     fontSize: 42,
                      //     letterSpacing: -0.5,
                      //     foreground: Paint()
                      //       ..style = PaintingStyle.stroke
                      //       ..strokeWidth = 1
                      //       ..color = image.lightestColor.withValues(alpha: 0.5),
                      //   ),
                      // ),
                      // Text(
                      //   image.title,
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //     height: 0.9,
                      //     fontFamily: FontFamily.yesevaOne,
                      //     package: 'design_system',
                      //     fontSize: 42,
                      //     letterSpacing: -0.5,
                      //     foreground: Paint()
                      //       ..blendMode = BlendMode.difference
                      //       ..color = image.lightestColor,
                      //   ),
                      // ),
                      Hero(
                        tag: '$_heroTitleTagPrefix${widget.image.uid}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            widget.image.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: 0.9,
                              fontFamily: FontFamily.yesevaOne,
                              package: 'design_system',
                              fontSize: 42,
                              letterSpacing: -0.5,
                              color: widget.image.darkestColor.withValues(
                                alpha: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final t = _animation.value.clamp(0.0, 1.0);
                  const k = 9.0;
                  final logT = math.log(1 + (k * t)) / math.log(1 + k);
                  final containerSize = 100 * logT;
                  final arrowScale = 1 + (0.7 * _animation.value);
                  final arrowColor =
                      Color.lerp(
                        widget.image.darkestColor,
                        widget.image.lightestColor,
                        _animation.value,
                      ) ??
                      widget.image.darkestColor;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: containerSize,
                        height: containerSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: arrowScale,
                        child: Assets.gifs.arrowDown.designImage(
                          height: 48,
                          color: arrowColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MagazineDetailPage extends StatefulWidget {
  const _MagazineDetailPage({required this.image});

  final ImageModel image;

  @override
  State<_MagazineDetailPage> createState() => _MagazineDetailPageState();
}

class _MagazineDetailPageState extends State<_MagazineDetailPage> {
  static const _dismissOverscrollOffset = -100.0;
  bool _didRequestPop = false;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_didRequestPop) return false;
    if (notification.metrics.pixels <= _dismissOverscrollOffset) {
      _didRequestPop = true;
      Navigator.of(context).maybePop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sentences = widget.image.description
        .split('.')
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList(growable: false);
    final sentenceRows = sentences.isEmpty
        ? <String>[widget.image.description.trim()]
        : sentences.map((sentence) => '$sentence.').toList(growable: false);

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyImageHeaderDelegate(
                image: widget.image,
              ),
            ),
            SliverToBoxAdapter(child: AnimatedDivider()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Hero(
                  tag: '$_heroTitleTagPrefix${widget.image.uid}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      widget.image.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 0.9,
                        fontFamily: FontFamily.yesevaOne,
                        package: 'design_system',
                        fontSize: 42,
                        letterSpacing: -0.5,
                        color: widget.image.lightestColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: AnimatedDivider()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ...List<Widget>.generate(sentenceRows.length, (index) {
              final isTextLeft = index.isEven;
              final sentence = sentenceRows[index];
              return SliverToBoxAdapter(
                child: MagazinePage(
                  sentence: sentence,
                  isTextLeft: isTextLeft,
                  imageUrl: widget.image.url,
                  viewportHeight: viewportHeight,
                  viewportWidth: viewportWidth,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StickyImageHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyImageHeaderDelegate({required this.image});

  final ImageModel image;

  @override
  double get maxExtent => 320;

  @override
  double get minExtent => 180;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    return SizedBox.expand(
      child: Opacity(
        opacity: opacity,
        child: Hero(
          tag: '$_heroImageTagPrefix${image.uid}',
          child: CachedNetworkImage(
            imageUrl: image.url,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Shimmer(child: Container(color: Colors.grey[300])),
            errorWidget: (context, url, error) => Container(
              color: Colors.black12,
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyImageHeaderDelegate oldDelegate) =>
      oldDelegate.image.uid != image.uid ||
      oldDelegate.image.url != image.url;
}

class AnimatedDivider extends StatefulWidget {
  const AnimatedDivider({super.key});

  @override
  State<AnimatedDivider> createState() => _AnimatedDividerState();
}

class _AnimatedDividerState extends State<AnimatedDivider> {
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    _animateIn();
  }

  Future<void> _animateIn() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {
      _visible = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Align(
        alignment: Alignment.center,
        child: AnimatedContainer(
          width: _visible ? 200 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: const Divider(),
        ),
      ),
    );
  }
}
