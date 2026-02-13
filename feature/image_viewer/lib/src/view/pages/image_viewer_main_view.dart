import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/bloc/image_viewer_bloc.dart';
import 'package:image_viewer/src/bloc/image_viewer_event.dart';
import 'package:image_viewer/src/bloc/image_viewer_state.dart';
import 'package:image_viewer/src/cubit/tts_cubit.dart';
import 'package:image_viewer/src/view/widgets/alerts/custom_dialog.dart';
import 'package:image_viewer/src/view/widgets/background/image_viewer_background.dart';
import 'package:image_viewer/src/view/widgets/control_bar.dart';
import 'package:image_viewer/src/view/widgets/image_carousel.dart';

const _slotCount = 5;
const _minColorsForShader = 4;
const _fallbackPalette = [
  Color(0xFF6B4E9D),
  Color(0xFF4A47A3),
  Color(0xFF1E88E5),
];

List<Color> _ensureMinColors(List<Color> colors) {
  if (colors.length >= _minColorsForShader) return colors;
  if (colors.isEmpty) return _ensureMinColors(List.of(_fallbackPalette));
  final out = List<Color>.from(colors);
  while (out.length < _minColorsForShader) {
    out.add(out[out.length % colors.length]);
  }
  return out;
}

/// Produces 5 colors by picking from each image per slot. ratio[i] = image index.
List<Color> _computeBlendedColors(List<ImageModel> images, List<int> ratio) {
  if (images.isEmpty) return _ensureMinColors(List.of(_fallbackPalette));
  final result = <Color>[];
  for (var i = 0; i < _slotCount; i++) {
    final imageIndex = (i < ratio.length ? ratio[i] : 0).clamp(
      0,
      images.length - 1,
    );
    final palette = images[imageIndex].colorPalette;
    final colorIndex = palette.isEmpty ? 0 : i % palette.length;
    result.add(
      palette.isEmpty
          ? _fallbackPalette[colorIndex % _fallbackPalette.length]
          : palette[colorIndex],
    );
  }
  return result;
}

/// Expects [BlocProvider<ImageViewerBloc>] from an ancestor (e.g. app router).
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({
    super.key,
    required this.onThemeToggle,
    this.onShareTap,
  });

  final VoidCallback onThemeToggle;
  final void Function(ImageModel?)? onShareTap;

  @override
  Widget build(BuildContext context) {
    return _ImageViewerContent(
      onThemeToggle: onThemeToggle,
      onShareTap: onShareTap,
    );
  }
}

class _ImageViewerContent extends StatefulWidget {
  const _ImageViewerContent({
    required this.onThemeToggle,
    this.onShareTap,
  });

  final VoidCallback onThemeToggle;
  final void Function(ImageModel?)? onShareTap;

  @override
  State<_ImageViewerContent> createState() => _ImageViewerContentState();
}

class _ImageViewerContentState extends State<_ImageViewerContent> {
  late final ValueNotifier<List<Color>> _blendedColorsNotifier;
  List<ImageModel>? _lastImages;
  ImageModel? _lastSelectedImage;
  bool _expandedView = false;

  @override
  void initState() {
    super.initState();
    _blendedColorsNotifier = ValueNotifier<List<Color>>(
      _ensureMinColors(List.of(_fallbackPalette)),
    );
  }

  @override
  void dispose() {
    _blendedColorsNotifier.dispose();
    super.dispose();
  }

  void _onVisibleRatioChange(List<ImageModel> images, List<int> ratio) {
    _blendedColorsNotifier.value = _computeBlendedColors(images, ratio);
  }

  void _onPageChange(List<ImageModel> images, int page) {
    if (page >= images.length) return;
    final image = images[page];
    _blendedColorsNotifier.value = image.colorPalette.isNotEmpty
        ? _ensureMinColors(List.of(image.colorPalette))
        : _computeBlendedColors(images, List.filled(_slotCount, page));
    final bloc = context.read<ImageViewerBloc>();
    bloc.add(UpdateSelectedImage(image: image));

    // Prefetch when nearing end (2 pages from last); skip if already loading
    if (page == images.length - 2 &&
        bloc.state.loadingType == ViewerLoadingType.none) {
      bloc.add(const ImageViewerFetchRequested());
    }
  }

  _toggleExpandedView({required bool expanded}) {
   
    setState(() {
      _expandedView = expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
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
            showCustomDialog(
              context: context,
              message: state.errorType.message,
              onDismiss: () {
                context.read<ImageViewerBloc>().add(const ErrorDismissed());
              },
              icon: const Icon(Icons.image_not_supported_outlined),
            );
          },
          builder: (context, state) {
            final isLoaded = state.visibleImages.isNotEmpty;
            final isLoading = state.loadingType != ViewerLoadingType.none;

            if (isLoaded) {
              _lastImages = state.visibleImages;
              _lastSelectedImage = state.selectedImage;
            }

            final images = isLoaded
                ? state.visibleImages
                : (isLoading ? _lastImages : null);
            final selectedImage = isLoaded
                ? state.selectedImage
                : _lastSelectedImage;
            final canShowContent =
                images != null &&
                images.isNotEmpty &&
                selectedImage != null &&
                selectedImage.url.isNotEmpty;

            return _CarouselControllerScope(
              images: images,
              selectedImage: selectedImage,
              canShowContent: canShowContent,
              blendedColorsNotifier: _blendedColorsNotifier,
              isLoaded: isLoaded,
              onVisibleRatioChange: _onVisibleRatioChange,
              onPageChange: _onPageChange,
              expandedView: _expandedView,
              onExpanded: (expanded) => _toggleExpandedView(expanded: expanded),
              onThemeToggle: widget.onThemeToggle,
              onNextPage: () =>
                  context.read<ImageViewerBloc>().add(AnotherImageEvent()),
              onShareTap: widget.onShareTap,
            );
          },
        ),
      ),
    );
  }
}

/// Owns PageController and provides nextPage for ControlBar.
class _CarouselControllerScope extends StatefulWidget {
  const _CarouselControllerScope({
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
  State<_CarouselControllerScope> createState() =>
      _CarouselControllerScopeState();
}

class _CarouselControllerScopeState extends State<_CarouselControllerScope> {
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
  void didUpdateWidget(covariant _CarouselControllerScope oldWidget) {
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
          mode: widget.expandedView
              ? MainButtonMode.audio
              : MainButtonMode.another,
          backgroundColor: widget.selectedImage?.lightestColor,
          onAnotherTap: () => nextPage(),
          onShareTap: widget.onShareTap,
          onPlayTapped: (playing) {
            if (playing) {
              final blocState = context.read<ImageViewerBloc>().state;
              if (blocState.selectedImage != null) {
                final text =
                    '${blocState.selectedImage?.title} ${blocState.selectedImage?.description}';
                context.read<TtsCubit>().play(text);
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
