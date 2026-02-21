part of 'image_viewer_main_view.dart';

/// Owns PageController and provides nextPage for ControlBar.
class CarouselControllerScope extends StatefulWidget {
  const CarouselControllerScope({
    required this.images,
    required this.selectedImage,
    required this.displayImageForColor,
    required this.canShowContent,
    required this.blendedColorsNotifier,
    required this.isLoaded,
    required this.onVisibleRatioChange,
    required this.onPageChange,
    required this.expandedView,
    required this.onExpanded,
    required this.onThemeToggle,
    this.onOpenGalleryRoute,
    required this.onNextPage,
    this.onShareTap,
  });

  final List<ImageModel>? images;
  final ImageModel? selectedImage;
  final ImageModel? displayImageForColor;
  final bool canShowContent;
  final ValueNotifier<List<Color>> blendedColorsNotifier;
  final bool isLoaded;
  final void Function(List<ImageModel> images, List<int> ratio)
  onVisibleRatioChange;
  final void Function(List<ImageModel> images, int page) onPageChange;
  final bool expandedView;
  final Function(bool) onExpanded;
  final VoidCallback onThemeToggle;
  final OpenGalleryRouteCallback? onOpenGalleryRoute;
  final VoidCallback onNextPage;
  final void Function(ImageModel?, {Uint8List? screenshotBytes})? onShareTap;

  @override
  State<CarouselControllerScope> createState() =>
      CarouselControllerScopeState();
}

class CarouselControllerScopeState extends State<CarouselControllerScope> {
  PageController? _pageController;
  final GlobalKey _screenshotKey = GlobalKey();
  ImageViewerBloc? _bloc;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc ??= context.read<ImageViewerBloc>();
    if (_pageController == null &&
        widget.canShowContent &&
        widget.images != null &&
        widget.selectedImage != null) {
      _initController();
    }
  }

  void _initController() {
    final images = widget.images!;
    final selected = widget.selectedImage!;
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
  void didUpdateWidget(covariant CarouselControllerScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.canShowContent &&
        widget.canShowContent &&
        widget.images != null &&
        widget.selectedImage != null &&
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
    final canShowContent = widget.canShowContent;
    final images = widget.images;
    final selectedImage = widget.selectedImage;

    return BlocBuilder<ScrollDirectionCubit, Axis>(
      builder: (context, scrollDirection) => Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            key: _screenshotKey,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // if (canShowContent &&
                //     images != null &&
                //     selectedImage != null) ...[
                //   if (widget.isLoaded)
                //     BlendedColorsSync(
                //       selectedImage: selectedImage,
                //       onSync: (colors) =>
                //           widget.blendedColorsNotifier.value = colors,
                //     ),
                  Positioned.fill(
                    child: AnimatedBackground(
                      colorsListenable: widget.blendedColorsNotifier,
                    ),
                  ),
                // ],

                if (canShowContent &&
                    images != null &&
                    selectedImage != null &&
                    _pageController != null)
                  ImageCarousel(
                    controller: _pageController,
                    images: images,
                    selectedID: selectedImage.uid,
                    scrollDirection: scrollDirection,
                    onVisibleRatioChange: (ratio) =>
                        widget.onVisibleRatioChange(images, ratio),
                    onPageChange: (page) => widget.onPageChange(images, page),
                    onExpanded: (expanded) => widget.onExpanded(expanded),
                  ),

                // BackgroundLoadingIndicator(
                //   key: ValueKey('carousel_loading_${widget.expandedView}'),
                //   visibleWhen: (state) => state.visibleImages.isEmpty,
                // ),
              ],
            ),
          ),

          ControlBar(
            backgroundColor: widget.displayImageForColor?.lightestColor,
            displayImageForColor: widget.displayImageForColor,
            carouselExpanded: widget.expandedView,
            mode: widget.expandedView
                ? MainButtonMode.audio
                : MainButtonMode.another,
            onAnotherTap: () => nextPage(),
            onShareTap: (img) => _onShareTap(img),
            onPlayTapped: (playing) {
              if (playing) {
                final blocState = context.read<ImageViewerBloc>().state;
                final img = blocState.selectedImage;
                if (img != null) {
                  context.read<TtsCubit>().play(img.title, img.description);
                }
              } else {
                context.read<TtsCubit>().stop();
              }
            },
          ),

          if (!widget.expandedView)
            _CarouselTopControls(
              onThemeToggle: widget.onThemeToggle,
              onOpenGallery: _openGalleryFromVisibleImages,
            ),
        ],
      ),
    );
  }
}
