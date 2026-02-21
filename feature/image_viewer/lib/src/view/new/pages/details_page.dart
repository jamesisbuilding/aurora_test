import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/new/pages/transformation_page.dart';
import 'package:image_viewer/src/view/new/widgets/overlays/shader_widget.dart';

class DetailsPage extends StatefulWidget {
  final ImageModel image;
  const DetailsPage({super.key, required this.image});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  bool _navingOut = false;
  int _currentIndex = 0;
  late String founderImageURL;
  late String bgImageURL;

  @override
  void initState() {
    super.initState();
    _pageController = PageController()..addListener(_listenForNav);

    if (widget.image.url ==
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d') {
      founderImageURL =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/nike%2Ffounder.png?alt=media';
      bgImageURL =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/nike%2Fbg.png?alt=media';
    } else if (widget.image.url ==
        'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa') {
      bgImageURL =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/space%2Fbg.png?alt=media';
      founderImageURL =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/space%2Ffounder.png?alt=media';
    } else if (widget.image.url ==
        'https://images.unsplash.com/photo-1519681393784-d120267933ba') {
      bgImageURL =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/mountain%2Fbg.png?alt=media';
      founderImageURL =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/mountain%2Ffounder.png?alt=media&token=cb715bce-a253-4b2a-93be-60d2c6ed47e6';
    } else if (widget.image.url ==
        'https://images.unsplash.com/photo-1501785888041-af3ef285b470') {
      bgImageURL =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/lake%2Fbg.png?alt=media&token=4347556c-6bc2-48fe-8b8c-df323d542776';
      founderImageURL =
          'https://firebasestorage.googleapis.com/v0/b/aurora-e6496.firebasestorage.app/o/lake%2Ffounder.png?alt=media&token=38bdc3d5-37b3-4787-9b0d-ea5ba414294c';
    } else {
      founderImageURL = widget.image.url;
      bgImageURL = widget.image.url;
    }
  }

  void _navigateOutIfNeeded(VoidCallback navigation) {
    if (_navingOut) return;
    _navingOut = true;
    navigation();
  }

  void _listenForNav() {
    // Remove the print in production, for debug only:
    // print(_pageController.offset);

    if (_pageController.offset < -100 && !_navingOut) {
      _navigateOutIfNeeded(() {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      });
      return;
    }

    if (_pageController.offset > MediaQuery.sizeOf(context).height + 100 &&
        !_navingOut) {
      _navigateOutIfNeeded(() {
        HapticFeedback.heavyImpact();
        Navigator.of(context)
            .push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return TransformationPage(image: widget.image);
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
              _navingOut = false;
            });
      });
      return;
    }
  }

  _updateIndex(int value) {
    HapticFeedback.lightImpact();
    _currentIndex = value;
    setState(() {});
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.image.colorPalette.first,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 20,
            child: Assets.gifs.arrowDown.designImage(
              height: 40,
              color: Colors.white,
            ),
          ),
          PageView(
            onPageChanged: _updateIndex,
            controller: _pageController,
            scrollDirection: Axis.vertical,
            children: [
              Container(
                height: MediaQuery.sizeOf(context).height,
                width: MediaQuery.sizeOf(context).width,
                color: widget.image.colorPalette.first,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Text(
                      'Meet the founder'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: -0.5,

                        fontWeight: FontWeight.w300,
                        foreground: Paint()
                          ..blendMode = BlendMode.difference
                          ..color = widget.image.lightestColor,
                      ),
                    ),
                    const SizedBox(height: 440,),

                    SizedBox(
                      width: 270,
                      child: Text(
                        '${widget.image.founderName}\n\n${widget.image.founderDescription}',

                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: -0.5,

                          height: 1,
                          fontWeight: FontWeight.w300,
                          foreground: Paint()
                            ..blendMode = BlendMode.difference
                            ..color = widget.image.lightestColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: MediaQuery.sizeOf(context).height,
                width: MediaQuery.sizeOf(context).width,
                color: widget.image.colorPalette[2],
                child: CachedImage(url: bgImageURL, fit: BoxFit.cover),
              ),
            ],
          ),
          IgnorePointer(
            ignoring: true,
            child: Column(
              spacing: 40,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: ValueKey('details_${widget.image.uid}'),
                  child: GyroParallaxCard(
                    enabled: _currentIndex == 1,
                    child: Center(
                      child: SizedBox(
                        width: 275,
                        height: 366,
                        child: CachedImage(
                          fit: BoxFit.cover,
                          url: founderImageURL,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 270),
              ],
            ),
          ),
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
        ],
      ),
    );
  }
}
