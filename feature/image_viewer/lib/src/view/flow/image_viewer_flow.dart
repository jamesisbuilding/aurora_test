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
class ImageViewerFlow extends StatefulWidget {
  const ImageViewerFlow({
    super.key,
    required this.getIt,
    required this.onThemeToggle,
    this.onShareTap,
  });

  final GetIt getIt;
  final VoidCallback onThemeToggle;
  final void Function(ImageModel?)? onShareTap;

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
          create: (_) => getIt<ImageViewerBloc>()
            ..add(const ImageViewerFetchRequested()),
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
            child: ImageViewerScreen(
              onThemeToggle: widget.onThemeToggle,
              onShareTap: widget.onShareTap,
            ),
          ),
          Transform.scale(
          scale: 1.15,
          child: Transform.translate(
            offset: Offset(0, -4),
            child: IgnorePointer(
              ignoring: _videoComplete,
              child: AnimatedOpacity(
                opacity: _videoComplete ? 0 : 1,
                duration: _fadeDuration,
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: VideoView(
                      onVideoComplete: _onVideoComplete,
                    ),
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
