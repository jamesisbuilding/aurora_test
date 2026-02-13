import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:image_viewer/src/utils/image_provider_utils.dart';

class ControlBarMainButton extends StatefulWidget {
  const ControlBarMainButton({
    super.key,
    required this.onAnotherTap,
    required this.mode,
    required this.onPlayTapped,
    this.controlBarExpanded = false,
    required this.carouselExpanded,
  });

  final Function onAnotherTap;
  final MainButtonMode mode;
  final Function(bool) onPlayTapped;
  final bool controlBarExpanded;
  final bool carouselExpanded;

  @override
  State<ControlBarMainButton> createState() => _ControlBarMainButtonState();
}

class _ControlBarMainButtonState extends State<ControlBarMainButton> {
  ImageProvider? _cachedBackgroundImage;
  String? _cachedImageUid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocBuilder<ImageViewerBloc, ImageViewerState>(
        buildWhen: (prev, curr) {
          return prev.selectedImage?.uid != curr.selectedImage?.uid ||
              curr.loadingType != prev.loadingType ||
              (curr.fetchedImages.isNotEmpty !=
                  prev.fetchedImages.isNotEmpty) ||
              (curr.fetchedImages.isNotEmpty &&
                  (prev.fetchedImages.isEmpty ||
                      prev.fetchedImages.first.uid !=
                          curr.fetchedImages.first.uid));
        },
        builder: (context, state) {
          final isLightMode = Theme.of(context).brightness == Brightness.light;
          final theme = Theme.of(context);

          final imageForColors =
              state.selectedImage ?? state.visibleImages.lastOrNull;
          Color? bgColor;
          Color? fgColor;
          if (imageForColors != null) {
            final lightest = imageForColors.lightestColor;
            final darkest = imageForColors.darkestColor;
            bgColor = isLightMode ? lightest : darkest;
            fgColor = isLightMode ? darkest : lightest;
          }
          bgColor ??= theme.colorScheme.surface;
          fgColor ??=
              theme.textTheme.labelLarge?.color ?? theme.colorScheme.onSurface;

          final atEndOfVisible =
              state.visibleImages.isNotEmpty &&
              state.selectedImage == state.visibleImages.last;

          final nextImageForBackground =
              atEndOfVisible && state.fetchedImages.isNotEmpty
                  ? state.fetchedImages.first
                  : state.selectedImage;

          final targetProvider =
              imageProviderForImage(nextImageForBackground);
          final targetUid = nextImageForBackground?.uid;

          if (targetUid != null && targetProvider != null) {
            if (targetUid != _cachedImageUid) {
              precacheImage(targetProvider, context).then((_) {
                if (mounted && targetUid == nextImageForBackground?.uid) {
                  setState(() {
                    _cachedBackgroundImage = targetProvider;
                    _cachedImageUid = targetUid;
                  });
                }
              });
            }
          }

          final effectiveBackgroundImage = targetUid == null
              ? null
              : (targetUid == _cachedImageUid
                  ? targetProvider
                  : _cachedBackgroundImage);

          return BlocBuilder<TtsCubit, TtsState>(
            builder: (context, ttsState) => MainButton(
              label: 'another',
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              backgroundImage: effectiveBackgroundImage,
              onTap: () => widget.onAnotherTap(),
              mode: state.loadingType == ViewerLoadingType.manual
                  ? MainButtonMode.audio
                  : widget.mode,
              onPlayTapped: (playing) => widget.onPlayTapped(playing),
              isPlaying: ttsState.isPlaying,
              isLoading:
                  (state.loadingType == ViewerLoadingType.manual &&
                      !widget.carouselExpanded) ||
                  ttsState.isLoading,
            ),
          );
        },
      ),
    );
  }
}
