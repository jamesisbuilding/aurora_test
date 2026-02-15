import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/bloc/image_viewer_bloc.dart';
import 'package:image_viewer/src/bloc/image_viewer_event.dart';
import 'package:image_viewer/src/cubit/cubit.dart';
import 'package:image_viewer/src/view/pages/image_viewer_main_view.dart';
import 'package:image_viewer/src/view/pages/video_view.dart';

const _fadeDuration = Duration(milliseconds: 600);

/// Orchestrates the image viewer flow: intro video first, then image viewer.
/// Image viewer preloads in the background whilst the video plays.
/// Creates and provides its own blocs via [getIt]; app has no knowledge of them.
/// [overlayBuilder] allows tests to inject a controllable overlay; when null, uses [VideoView].
class ImageViewerFlow extends StatefulWidget {
  const ImageViewerFlow({
    super.key,
    required this.getIt,
    required this.onThemeToggle,
    this.onShareTap,
    this.overlayBuilder,
    this.bottomLayer,
  });

  final GetIt getIt;
  final VoidCallback onThemeToggle;
  final void Function(ImageModel?, {Uint8List? screenshotBytes})? onShareTap;

  /// Optional. When provided, used instead of [VideoView] for the overlay.
  /// Receives [onVideoComplete] to trigger the fade-out transition.
  final Widget Function(VoidCallback onVideoComplete)? overlayBuilder;

  /// Optional. When provided, used instead of [ImageViewerScreen] for the bottom layer.
  /// Allows tests to avoid heavy dependencies (shaders, network, etc.).
  final Widget? bottomLayer;

  @override
  State<ImageViewerFlow> createState() => _ImageViewerFlowState();
}

class _ImageViewerFlowState extends State<ImageViewerFlow> {
  bool _videoComplete = false;

  void _onVideoComplete() {
    setState(() => _videoComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final getIt = widget.getIt;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<ImageViewerBloc>()..add(const ImageViewerFetchRequested()),
        ),
        BlocProvider(create: (_) => getIt<TtsCubit>()),
        BlocProvider(create: (_) => getIt<FavouritesCubit>()),
        BlocProvider(create: (_) => getIt<CollectedColorsCubit>()),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom layer: image viewer preloads whilst video plays
          Positioned.fill(
            child: widget.bottomLayer ??
                ImageViewerScreen(
                  onThemeToggle: widget.onThemeToggle,
                  onShareTap: widget.onShareTap,
                  videoComplete: _videoComplete,
                ),
          ),
          Transform.scale(
            scale: 1.15,
            child: Transform.translate(
              offset: Offset(0, -25),
              child: IgnorePointer(
                ignoring: _videoComplete,
                child: AnimatedOpacity(
                  opacity: _videoComplete ? 0 : 1,
                  duration: _fadeDuration,
                  child: ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: widget.overlayBuilder != null
                          ? widget.overlayBuilder!(_onVideoComplete)
                          : VideoView(onVideoComplete: _onVideoComplete),
                    ),
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
