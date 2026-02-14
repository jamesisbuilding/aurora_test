part of 'image_viewer_main_view.dart';

class _ImageViewerContent extends StatefulWidget {
  const _ImageViewerContent({
    required this.onThemeToggle,
    this.onShareTap,
    this.videoComplete = true,
  });

  final VoidCallback onThemeToggle;
  final void Function(ImageModel?, {Uint8List? screenshotBytes})? onShareTap;
  final bool videoComplete;

  @override
  State<_ImageViewerContent> createState() => _ImageViewerContentState();
}

class _ImageViewerContentState extends State<_ImageViewerContent> {
  late final ValueNotifier<List<Color>> _blendedColorsNotifier;
  List<ImageModel>? _lastImages;
  ImageModel? _lastSelectedImage;
  ImageModel? _displayImageForColor;
  bool _expandedView = false;

  @override
  void initState() {
    super.initState();
    _blendedColorsNotifier = ValueNotifier<List<Color>>(
      ensureMinColors(List.of(imageViewerFallbackPalette)),
    );
  }

  @override
  void didUpdateWidget(covariant _ImageViewerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Video just completed: show any startup error that was suppressed
    if (!oldWidget.videoComplete && widget.videoComplete && mounted) {
      final state = context.read<ImageViewerBloc>().state;
      if (state.visibleImages.isEmpty &&
          state.errorType != ViewerErrorType.none) {
        showCustomDialog(
          context: context,
          message: state.errorType.message,
          onDismiss: () {
            context.read<ImageViewerBloc>().add(const ErrorDismissed());
            context.read<ImageViewerBloc>().add(
                  const ImageViewerFetchRequested(
                    loadingType: ViewerLoadingType.manual,
                  ),
                );
          },
        );
      }
    }
  }

  Future<void> _precacheThenUpdateDisplayImage(ImageModel image) async {
    final provider = imageProviderForImage(image);
    if (provider == null) {
      if (mounted) setState(() => _displayImageForColor = image);
      return;
    }
    try {
      await precacheImage(provider, context);
    } catch (_) {
      // Fallback: update anyway to avoid being stuck
    }
    if (!mounted) return;
    final bloc = context.read<ImageViewerBloc>();
    if (bloc.state.selectedImage?.uid == image.uid) {
      setState(() => _displayImageForColor = image);
    }
  }

  @override
  void dispose() {
    _blendedColorsNotifier.dispose();
    super.dispose();
  }

  void _onVisibleRatioChange(List<ImageModel> images, List<int> ratio) {
    _blendedColorsNotifier.value = computeBlendedColors(images, ratio);
  }

  void _onPageChange(List<ImageModel> images, int page) {
    if (page >= images.length) return;
    final image = images[page];
    _blendedColorsNotifier.value = image.colorPalette.isNotEmpty
        ? ensureMinColors(List.of(image.colorPalette))
        : computeBlendedColors(images, List.filled(imageViewerSlotCount, page));
    final bloc = context.read<ImageViewerBloc>();
    bloc.add(UpdateSelectedImage(image: image));

    // Stop TTS when switching images so highlight matches the visible content
    context.read<TtsCubit>().stop();

    // Prefetch when nearing end (2 pages from last); skip if already loading
    if (page == images.length - 2 &&
        bloc.state.loadingType == ViewerLoadingType.none) {
      bloc.add(const ImageViewerFetchRequested());
    }
  }

  void _toggleExpandedView({required bool expanded}) {
    if (!expanded) {
      context.read<TtsCubit>().stop();
    }
    setState(() {
      _expandedView = expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height,
            width: MediaQuery.sizeOf(context).width,
            child: BlocConsumer<ImageViewerBloc, ImageViewerState>(
              buildWhen: (prev, curr) {
                return prev.visibleImages.length != curr.visibleImages.length ||
                    prev.selectedImage != curr.selectedImage ||
                    prev.errorType != curr.errorType;
              },
              listenWhen: (prev, curr) =>
                  prev.errorType != curr.errorType &&
                  curr.errorType != ViewerErrorType.none,
              listener: (context, state) {
                final hasNoVisibleImages = state.visibleImages.isEmpty;
                // Startup failure: only show error after video has finished
                if (hasNoVisibleImages && !widget.videoComplete) return;
                showCustomDialog(
                  context: context,
                  message: state.errorType.message,
                  onDismiss: () {
                    context.read<ImageViewerBloc>().add(const ErrorDismissed());
                    if (hasNoVisibleImages) {
                      context.read<ImageViewerBloc>().add(
                            const ImageViewerFetchRequested(
                              loadingType: ViewerLoadingType.manual,
                            ),
                          );
                    }
                  },
                );
              },
              builder: (context, state) {
                final isLoaded = state.visibleImages.isNotEmpty;
                final isLoading = state.loadingType != ViewerLoadingType.none;

                if (isLoaded) {
                  _lastImages = state.visibleImages;
                  _lastSelectedImage = state.selectedImage;
                  final newSelected = state.selectedImage;
                  if (newSelected != null &&
                      newSelected.uid != _displayImageForColor?.uid) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _precacheThenUpdateDisplayImage(newSelected);
                    });
                  }
                }

                final images = isLoaded
                    ? state.visibleImages
                    : (isLoading ? _lastImages : null);
                final selectedImage =
                    isLoaded ? state.selectedImage : _lastSelectedImage;
                final canShowContent =
                    images != null &&
                    images.isNotEmpty &&
                    selectedImage != null &&
                    selectedImage.url.isNotEmpty;

                return CarouselControllerScope(
                  images: images,
                  selectedImage: selectedImage,
                  displayImageForColor: _displayImageForColor ?? selectedImage,
                  canShowContent: canShowContent,
                  blendedColorsNotifier: _blendedColorsNotifier,
                  isLoaded: isLoaded,
                  onVisibleRatioChange: _onVisibleRatioChange,
                  onPageChange: _onPageChange,
                  expandedView: _expandedView,
                  onExpanded: (expanded) =>
                      _toggleExpandedView(expanded: expanded),
                  onThemeToggle: widget.onThemeToggle,
                  onNextPage: () =>
                      context.read<ImageViewerBloc>().add(AnotherImageEvent()),
                  onShareTap: widget.onShareTap,
                );
              },
            ),
          ),
          if (kDebugMode) const BlocStateDebugOverlay(),
        ],
      ),
    );
  }
}
