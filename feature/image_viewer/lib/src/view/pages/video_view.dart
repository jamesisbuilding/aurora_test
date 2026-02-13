import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays the intro video asset from [Assets.video.intro].
/// Calls [onVideoComplete] when playback finishes.
/// Tapping the video will stop playback and exit (calls [onVideoComplete]).
class VideoView extends StatefulWidget {
  const VideoView({super.key, this.onVideoComplete});

  final VoidCallback? onVideoComplete;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late final VideoPlayerController _controller;
  bool _completedNotified = false;

  void _checkCompletion() {
    if (_completedNotified) return;
    final value = _controller.value;
    if (value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 100)) {
      _completedNotified = true;
      widget.onVideoComplete?.call();
    }
  }



  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(Assets.video.intro)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.addListener(_checkCompletion);
      });
  }

  @override
  void dispose() {
    _controller.removeListener(_checkCompletion);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Assets.video.thumbnail.designImage(
          key: const ValueKey('thumbnail'),
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
        ),
        if (_controller.value.isInitialized)
          AspectRatio(
            key: const ValueKey('video'),
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
      ],
    );
  }
}
