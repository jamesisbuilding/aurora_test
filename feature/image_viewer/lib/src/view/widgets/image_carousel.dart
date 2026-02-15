import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utils/utils.dart';
import 'package:image_analysis_service/src/domain/models/image_model.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer.dart';

/// Ratio array granularity. E.g. 5 means [0,0,1,1,1] for 40% current / 60% next.
const _defaultGranularity = 5;

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    super.key,
    required this.onPageChange,
    this.onVisibleRatioChange,
    required this.images,
    required this.selectedID,
    this.granularity = _defaultGranularity,
    this.controller,
    required this.onExpanded,
    this.scrollDirection = Axis.vertical,
  });

  final void Function(int page) onPageChange;

  /// Vertical (up/down) or horizontal (left/right) scroll.
  final Axis scrollDirection;

  /// Called during scroll with ratio array. E.g. [0,0,1,1,1] = current 2/5, next 3/5.
  final void Function(List<int> ratio)? onVisibleRatioChange;
  final List<ImageModel> images;
  final String selectedID;
  final int granularity;
  final Function(bool) onExpanded;

  /// Optional controller; when provided, this widget does not own or dispose it.
  final PageController? controller;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  bool _ownsController = false;
  String _expandedID = '';
  int? _lastPageIndex;
  final Set<int> _seenIndices = {};

  static const _viewportFraction = 0.8;

  @override
  void initState() {
    super.initState();
    final initialPage = _initialPage;
    _lastPageIndex = initialPage;
    _seenIndices.add(initialPage);
    if (widget.controller != null) {
      _pageController = widget.controller!;
      _ownsController = false;
    } else {
      _pageController = PageController(
        viewportFraction: _viewportFraction,
        initialPage: initialPage,
      );
      _ownsController = true;
    }
    _pageController.addListener(_onPageChanged);
    _emitRatio(
      _pageController.hasClients
          ? (_pageController.page ?? initialPage.toDouble())
          : initialPage.toDouble(),
    );
  }

  void _onPageChange(int page) {
    _seenIndices.add(page);
    widget.onPageChange(page);
    if (_lastPageIndex != null && page != _lastPageIndex) {
      _expandedID = '';
    }
    _lastPageIndex = page;
    setState(noop);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    if (_ownsController) _pageController.dispose();
    super.dispose();
  }

  int get _initialPage {
    final index = widget.images.indexWhere((i) => i.uid == widget.selectedID);
    return index >= 0 ? index : 0;
  }

  void _onPageChanged() {
    final page = _pageController.page ?? 0;
    _emitRatio(page);
  }

  void _emitRatio(double fractionalPage) {
    widget.onVisibleRatioChange?.call(_computeRatio(fractionalPage));
  }

  /// Returns array of indices representing visible ratio, e.g. [0,0,1,1,1].
  List<int> _computeRatio(double fractionalPage) {
    final g = widget.granularity;
    final currentIndex = fractionalPage.floor().clamp(
      0,
      widget.images.length - 1,
    );
    final fractionalPart = fractionalPage - currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, widget.images.length - 1);
    // fractionalPart 0 = 100% current, 1 = 100% next
    final currentFraction = 1 - fractionalPart;

    final slotsForCurrent = (currentFraction * g).round();
    final slotsForNext = g - slotsForCurrent;

    return [
      ...List.filled(slotsForCurrent, currentIndex),
      ...List.filled(slotsForNext, nextIndex),
    ];
  }

  _toggleExpanded({required bool selected, required String imageUID}) {
    if (selected) {
      setState(() {
        _expandedID = imageUID;
      });
    } else {
      setState(() {
        _expandedID = '';
      });
    }
    widget.onExpanded(selected);
  }

  Color? _backgroundColor(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool expanded = _expandedID.isNotEmpty;

    if (!expanded) return Colors.transparent;

    final selected = widget.images
        .where((i) => i.uid == widget.selectedID)
        .firstOrNull;
    if (selected == null) return Colors.transparent;

    return isLightMode ? selected.lightestColor : selected.darkestColor;
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = MediaQuery.sizeOf(context).width * _viewportFraction;
    return AnimatedContainer(
      
      duration: const Duration(seconds: 1),
      color: _backgroundColor(context),
      height: MediaQuery.sizeOf(context).height,
      child: PageView.builder(
        
        physics: _expandedID.isNotEmpty
            ? const NeverScrollableScrollPhysics()
            : null,
        controller: _pageController,
        scrollDirection: widget.scrollDirection,
        padEnds: true,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          HapticFeedback.lightImpact();
          _onPageChange(index);
        },
        itemBuilder: (context, index) {
          final image = widget.images[index];
          final seen = _seenIndices.contains(index);
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: itemWidth),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: seen
                      ? ImageViewer(
                          key: ValueKey('image_${image.uid}'),
                          image: image,
                          selected: image.uid == widget.selectedID,
                          disabled: _expandedID.isNotEmpty,
                          expanded:
                              _expandedID == image.uid &&
                              image.uid == widget.selectedID,
                          onTap: (selected) => _toggleExpanded(
                            selected: selected,
                            imageUID: image.uid,
                          ),
                        )
                      : SizedBox(height: itemWidth, width: itemWidth),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
