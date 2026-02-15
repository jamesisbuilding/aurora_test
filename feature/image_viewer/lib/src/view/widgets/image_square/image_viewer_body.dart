import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_body_constants.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_body_content.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_body_reveal.dart';
import 'package:image_viewer/src/view/widgets/image_square/palette_explosion.dart';
import 'package:tts_service/tts_service.dart';

class ImageViewerBody extends StatefulWidget {
  final ImageModel image;
  final TtsCurrentWord? currentWord;
  final Function(bool) onColorsExpanded;
  final bool visible;
  final ScrollController? scrollController;
  final int? paragraphCount;

  const ImageViewerBody({
    super.key,
    required this.image,
    required this.onColorsExpanded,
    required this.visible,
    this.currentWord,
    this.scrollController,
    this.paragraphCount,
  });

  @override
  State<ImageViewerBody> createState() => _ImageViewerBodyState();
}

class _ImageViewerBodyState extends State<ImageViewerBody> {
  bool? _contentFitsViewport;
  int _maxRevealedIndex = -1;
  final Set<int> _hapticForBlockIndices = {};
  ScrollController? get _scroll => widget.scrollController;

  @override
  void initState() {
    super.initState();
    _scroll?.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contentFitsViewport == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkContentFits());
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ImageViewerBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.uid != widget.image.uid) {
      _contentFitsViewport = null;
      _maxRevealedIndex = -1;
      _hapticForBlockIndices.clear();
    }
  }

  /// Block 0=title, 1=para0, 2=dot, 3=para1, 4=dot, ...; paragraph (text) at 1,3,5,7...
  bool _isParagraphBlock(int index) => index >= 1 && index.isOdd;

  int get _paragraphCount =>
      widget.paragraphCount ??
      widget.image.description
          .split('.')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .length;

  void _checkContentFits() {
    if (!mounted || _scroll == null || !_scroll!.hasClients) return;
    final position = _scroll!.position;
    final fits = position.maxScrollExtent <= 0;
    if (_contentFitsViewport != fits) {
      setState(() {
        _contentFitsViewport = fits;
        if (fits == false) _maxRevealedIndex = 0;
      });
      _onScroll();
    }
  }

  void _onScroll() {
    if (!mounted || _contentFitsViewport != false || _scroll == null) return;
    if (!_scroll!.hasClients) return;
    final position = _scroll!.position;
    final viewportHeight = position.viewportDimension;
    final step = viewportHeight * scrollRevealFraction;
    final scrollOffset = position.pixels;
    final revealed = step <= 0 ? 999 : (scrollOffset / step).floor();
    if (revealed > _maxRevealedIndex) {
      for (var i = _maxRevealedIndex + 1; i <= revealed; i++) {
        if (_isParagraphBlock(i) &&
            !_hapticForBlockIndices.contains(i) &&
            _hapticForBlockIndices.length < _paragraphCount) {
          _hapticForBlockIndices.add(i);
          HapticFeedback.lightImpact();
        }
      }
      setState(() => _maxRevealedIndex = revealed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useScrollReveal =
        _contentFitsViewport == false && widget.scrollController != null;
    final descBlocks = ImageViewerBodyContent.buildDescriptionBlocks(
      context,
      widget.image,
      widget.currentWord,
    );

    final titleBlock = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: ImageViewerBodyContent.buildTitleText(
        context,
        widget.image.title,
        widget.image,
        widget.currentWord,
      ),
    );

    final titleWidget = useScrollReveal
        ? wrapScrollReveal(titleBlock, 0, _maxRevealedIndex)
        : wrapTimeReveal(titleBlock, bodyDelayStartMs);

    final descriptionChildren = <Widget>[];
    if (useScrollReveal) {
      for (var i = 0; i < descBlocks.length; i++) {
        descriptionChildren.add(
          wrapScrollReveal(
            Padding(padding: EdgeInsets.zero, child: descBlocks[i]),
            1 + i,
            _maxRevealedIndex,
          ),
        );
      }
    } else {
      var delayMs = bodyDelayStartMs + bodyDelayStepMs;
      for (var i = 0; i < descBlocks.length; i++) {
        descriptionChildren.add(wrapTimeReveal(descBlocks[i], delayMs));
        delayMs += bodyDelayStepMs;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PaletteInteraction(
          colors: widget.image.colorPalette,
          image: widget.image,
          onChanged: (expanded) => widget.onColorsExpanded(expanded),
        ),
        const SizedBox(height: 20),
        AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: titleWidget,
        ),
        DelayedDisplay(
          delay: const Duration(seconds: 1),
          child: Assets.gifs.arrowDown.designImage(height: 40, width: 40, color: Theme.of(context).colorScheme.onSurface)),
        AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: descriptionChildren,
            ),
          ),
        ),
        const SizedBox(height: 160),
      ],
    );
  }
}
