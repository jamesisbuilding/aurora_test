import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:image_viewer/src/view/new/pages/image_gallery.dart';
import 'package:image_viewer/src/view/new/pages/image_page.dart';
import 'package:image_viewer/src/view/new/widgets/button/liquid_glass_button.dart';
import 'package:image_viewer/src/view/new/widgets/overlays/shader_widget.dart';
import 'package:image_viewer/src/view/widgets/background/image_viewer_background.dart';

class ImageCarouselNew extends StatefulWidget {
  const ImageCarouselNew({super.key});

  @override
  State<ImageCarouselNew> createState() => _ImageCarouselNewState();
}

class _ImageCarouselNewState extends State<ImageCarouselNew> {
  PageController? _pageController;
  ImageViewerBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc ??= context.read<ImageViewerBloc>();

    final state = _bloc!.state;
    // Only initialize the controller if requirements are met and it's not already set.
    if (_pageController == null &&
        state.visibleImages.isNotEmpty &&
        state.selectedImage != null) {
      _initController();
    }
  }

  void _initController() {
    final state = _bloc!.state;
    final images = state.visibleImages;
    final selected = state.selectedImage;
    if (images.isEmpty || selected == null) return;

    final initialPage = images
        .indexWhere((i) => i.uid == selected.uid)
        .clamp(0, images.length - 1);

    _pageController = PageController(
      viewportFraction: 1,
      initialPage: initialPage,
    );
    _bloc!.add(CarouselControllerRegistered(controller: _pageController!));
  }

  @override
  void didUpdateWidget(covariant ImageCarouselNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = _bloc?.state;
    // If content becomes available and controller is missing, init.
    if (state != null &&
        state.visibleImages.isNotEmpty &&
        state.selectedImage != null &&
        _pageController == null) {
      _initController();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _bloc?.add(const CarouselControllerUnregistered());
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageViewerBloc, ImageViewerState>(
      buildWhen: (previous, current) =>
          previous.visibleImages.length != current.visibleImages.length ||
          previous.selectedImage != current.selectedImage ||
          previous.loadingType != current.loadingType,
      builder: (context, state) {
        return Scaffold(
          body: SizedBox(
            height: MediaQuery.sizeOf(context).height,
            width: MediaQuery.sizeOf(context).width,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                if (state.selectedImage != null)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedBackground(
                        imageColors: state.selectedImage?.colorPalette,
                      ),
                    ),
                  ),
                PageView.builder(
                  controller: _pageController, // Use our managed controller
                  onPageChanged: (value) => context.read<ImageViewerBloc>().add(
                    UpdateSelectedImage(image: state.visibleImages[value]),
                  ),
                  itemCount: state.visibleImages.length,
                  itemBuilder: (context, index) {
                    return ImagePage(image: state.visibleImages[index]);
                  },
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
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: LiquidGlassButton(
                    onGalleryTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ImageGallery(images: state.visibleImages);
                          },
                        ),
                      );
                    },
                    label: 'another',
                    isLoading: state.loadingType == ViewerLoadingType.manual,
                    onTap: () => context.read<ImageViewerBloc>().add(
                      AnotherImageEvent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
