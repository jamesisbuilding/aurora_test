import 'dart:async';

import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:utils/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/cubit/cubit.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_body.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_square.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer({
    super.key,
    required this.image,
    this.isLoading = false,
    this.errorMessage,
    required this.selected,
    this.onTap,
    required this.disabled,
    required this.expanded,
    this.hasEverExpanded = false,
  });

  final ImageModel image;
  final Function(bool)? onTap;
  final bool isLoading;
  final String? errorMessage;
  final bool selected;
  final bool disabled;
  final bool expanded;

  /// When false, the touch hint can show after 3s idle on the selected image.
  final bool hasEverExpanded;

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

const _touchHintIdleDuration = Duration(seconds: 3);

class _ImageViewerState extends State<ImageViewer> with AnimatedPressMixin {
  bool _colorsExpanded = false;
  late final ScrollController _scrollController;
  Timer? _touchHintTimer;
  bool _showTouchHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scheduleTouchHintIfNeeded();
  }

  @override
  void dispose() {
    _cancelTouchHint();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _shouldShowTouchHint =>
      widget.selected && !widget.expanded && !widget.hasEverExpanded;

  void _scheduleTouchHintIfNeeded() {
    _cancelTouchHint();
    if (!_shouldShowTouchHint) return;
    _touchHintTimer = Timer(_touchHintIdleDuration, () {
      if (mounted && _shouldShowTouchHint) {
        setState(() => _showTouchHint = true);
      }
    });
  }

  void _cancelTouchHint() {
    _touchHintTimer?.cancel();
    _touchHintTimer = null;
    if (_showTouchHint) setState(() => _showTouchHint = false);
  }

  @override
  void onPressComplete() {
    _cancelTouchHint();
    if (_colorsExpanded) {
      return;
    }
    widget.onTap?.call(!widget.disabled);
    setState(noop);
  }

  @override
  void didUpdateWidget(covariant ImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected ||
        oldWidget.expanded != widget.expanded ||
        oldWidget.hasEverExpanded != widget.hasEverExpanded) {
      if (_shouldShowTouchHint) {
        _scheduleTouchHintIfNeeded();
      } else {
        _cancelTouchHint();
      }
      setState(noop);
    }
  }

  _toggleColorsExpanded({required bool value}) {
    setState(() {
      _colorsExpanded = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: widget.expanded ? MediaQuery.sizeOf(context).height : 500,
        child: AnimatedOpacity(
          opacity: !widget.selected && widget.disabled ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: widget.expanded ? null : const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final imageCard = Padding(
      padding: const EdgeInsets.all(20.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GyroParallaxCard(
              enabled: (widget.selected && !widget.disabled) || widget.expanded,
              child: Hero(
                tag: 'gallery_hero_${widget.image.uid}',
                flightShuttleBuilder: (
                  flightContext,
                  animation,
                  flightDirection,
                  fromHeroContext,
                  toHeroContext,
                ) {
                  return _HeroFlightImage(url: widget.image.url);
                },
                placeholderBuilder: (context, heroSize, child) {
                  return _HeroFlightImage(url: widget.image.url);
                },
                child: ImageViewerSquare(
                  localPath: widget.image.localPath,
                  networkPath: widget.image.url,
                  imageUid: widget.image.uid,
                  lightestColor: widget.image.lightestColor,
                ),
              ),
            ),
            if (_showTouchHint)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Padding(
                    padding: const EdgeInsets.all(100.0),
                    child: IgnorePointer(
                      child: Center(
                        child: Assets.gifs.touch.designImage(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return [
      buildPressable(
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _colorsExpanded ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: DelayedDisplay(child: imageCard),
          ),
        ),
      ),
      if (widget.expanded)
        BlocBuilder<TtsCubit, TtsState>(
          buildWhen: (prev, curr) => prev.currentWord != curr.currentWord,
          builder: (context, ttsState) => ImageViewerBody(
            image: widget.image,
            currentWord: ttsState.currentWord,
            visible: !_colorsExpanded,
            scrollController: _scrollController,
            onColorsExpanded: (colorsExpanded) =>
                _toggleColorsExpanded(value: colorsExpanded),
          ),
        ),
    ];
  }
}

class _HeroFlightImage extends StatelessWidget {
  const _HeroFlightImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // borderRadius: BorderRadius.circular(12),
      child: url.isEmpty
          ? ColoredBox(color: Theme.of(context).colorScheme.onSurface)
          : CachedImage(
              url: url,
              fit: BoxFit.cover,
              // borderRadius: BorderRadius.circular(12),
            ),
    );
  }
}
