part of 'image_viewer_main_view.dart';

/// Owns PageController and provides nextPage for ControlBar.
class CarouselControllerScope extends StatefulWidget {
  const CarouselControllerScope({
    required this.images,
    required this.selectedImage,
    required this.canShowContent,
    required this.blendedColorsNotifier,
    required this.isLoaded,
    required this.onVisibleRatioChange,
    required this.onPageChange,
    required this.expandedView,
    required this.onExpanded,
    required this.onThemeToggle,
    required this.onNextPage,
    this.onShareTap,
  });

  final List<ImageModel>? images;
  final ImageModel? selectedImage;
  final bool canShowContent;
  final ValueNotifier<List<Color>> blendedColorsNotifier;
  final bool isLoaded;
  final void Function(List<ImageModel> images, List<int> ratio)
  onVisibleRatioChange;
  final void Function(List<ImageModel> images, int page) onPageChange;
  final bool expandedView;
  final Function(bool) onExpanded;
  final VoidCallback onThemeToggle;
  final Function onNextPage;
  final void Function(ImageModel?)? onShareTap;

  @override
  State<CarouselControllerScope> createState() =>
      CarouselControllerScopeState();
}

class CarouselControllerScopeState extends State<CarouselControllerScope> {
  PageController? _pageController;

  static const _viewportFraction = 0.8;

  void nextPage() {
    widget.onNextPage();
  }

  @override
  void initState() {
    super.initState();
    if (widget.canShowContent &&
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
      viewportFraction: _viewportFraction,
      initialPage: initialPage,
    );
    context.read<ImageViewerBloc>().add(
      CarouselControllerRegistered(controller: _pageController!),
    );
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
    if (_pageController != null) {
      context.read<ImageViewerBloc>().add(
        const CarouselControllerUnregistered(),
      );
    }
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canShowContent = widget.canShowContent;
    final images = widget.images;
    final selectedImage = widget.selectedImage;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (canShowContent && images != null && selectedImage != null) ...[
          if (widget.isLoaded)
            _BlendedColorsSync(
              selectedImage: selectedImage,
              onSync: (colors) => widget.blendedColorsNotifier.value = colors,
            ),
          Positioned.fill(
            child: AnimatedBackground(
              colorsListenable: widget.blendedColorsNotifier,
            ),
          ),
        ],
        if (canShowContent &&
            images != null &&
            selectedImage != null &&
            _pageController != null)
          ImageCarousel(
            controller: _pageController,
            images: images,
            selectedID: selectedImage.uid,
            onVisibleRatioChange: (ratio) =>
                widget.onVisibleRatioChange(images, ratio),
            onPageChange: (page) => widget.onPageChange(images, page),
            onExpanded: (expanded) => widget.onExpanded(expanded),
          ),
        ControlBar(
          carouselExpanded: widget.expandedView,
          mode: widget.expandedView
              ? MainButtonMode.audio
              : MainButtonMode.another,
          backgroundColor: widget.selectedImage?.lightestColor,
          onAnotherTap: () => nextPage(),
          onShareTap: widget.onShareTap,
          onPlayTapped: (playing) {
            if (playing) {
              final blocState = context.read<ImageViewerBloc>().state;
              final img = blocState.selectedImage;
              if (img != null) {
                context
                    .read<TtsCubit>()
                    .play(img.title, img.description);
              }
            } else {
              context.read<TtsCubit>().stop();
            }
          },
        ),

        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 16,
          child: ThemeSwitch(onThemeToggle: widget.onThemeToggle),
        ),
      ],
    );
  }
}

/// Syncs blended colors when bloc state changes (e.g. fetch, initial load).
class _BlendedColorsSync extends StatefulWidget {
  const _BlendedColorsSync({required this.selectedImage, required this.onSync});

  final ImageModel selectedImage;
  final void Function(List<Color>) onSync;

  @override
  State<_BlendedColorsSync> createState() => _BlendedColorsSyncState();
}

class _BlendedColorsSyncState extends State<_BlendedColorsSync> {
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    _syncIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _BlendedColorsSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncIfNeeded();
  }

  void _syncIfNeeded() {
    if (_lastSyncedUid == widget.selectedImage.uid) return;
    _lastSyncedUid = widget.selectedImage.uid;
    final palette = widget.selectedImage.colorPalette;
    widget.onSync(
      _ensureMinColors(
        palette.isNotEmpty ? List.of(palette) : List.of(_fallbackPalette),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
