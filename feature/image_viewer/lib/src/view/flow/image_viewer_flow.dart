import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:get_it/get_it.dart';
import 'package:image_viewer/src/bloc/image_viewer_bloc.dart';
import 'package:image_viewer/src/bloc/image_viewer_event.dart';
import 'package:image_viewer/src/cubit/cubit.dart';
import 'package:image_viewer/src/di/image_viewer_app_services.dart';
import 'package:image_viewer/src/view/new/image_carousel_new.dart';
import 'package:image_viewer/src/view/pages/image_viewer_main_view.dart';
import 'package:image_viewer/src/view/pages/video_view.dart';
import 'package:image_viewer/src/view/widgets/alerts/custom_dialog.dart';

const _fadeDuration = Duration(milliseconds: 600);

/// Orchestrates the image viewer flow: intro video first, then image viewer.
/// Image viewer preloads in the background whilst the video plays.
/// Creates and provides its own blocs via [getIt]; app has no knowledge of them.
/// [overlayBuilder] allows tests to inject a controllable overlay; when null, uses [VideoView].
class ImageViewerFlow extends StatefulWidget {
  const ImageViewerFlow({
    super.key,
    required this.getIt,
    this.onThemeToggle,
    this.onShareTap,
    this.onOpenGalleryRoute,
    this.overlayBuilder,
    this.bottomLayer,
  });

  final GetIt getIt;
  final VoidCallback? onThemeToggle;
  final ImageViewerShareTapCallback? onShareTap;
  final OpenGalleryRouteCallback? onOpenGalleryRoute;

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
  bool _firstCollectedColorsAlertShown = false;

  void _onVideoComplete() {
    setState(() => _videoComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final getIt = widget.getIt;
    final appServices = getIt<ImageViewerAppServices>();
    final onThemeToggle = widget.onThemeToggle ?? appServices.onThemeToggle;
    final onShareTap = widget.onShareTap ?? appServices.onShareTap;
    final onOpenGalleryRoute =
        widget.onOpenGalleryRoute ?? appServices.onOpenGalleryRoute;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<ImageViewerBloc>()..add(const ImageViewerFetchRequested(count: 5)),
        ),
        BlocProvider(create: (_) => getIt<TtsCubit>()),
        BlocProvider(create: (_) => getIt<FavouritesCubit>()),
        BlocProvider(create: (_) => getIt<CollectedColorsCubit>()),
        BlocProvider(create: (_) => getIt<ScrollDirectionCubit>()),
      ],
      child: BlocListener<CollectedColorsCubit, Map<String, List<Color>>>(
        listenWhen: (previous, current) =>
            previous.isEmpty &&
            current.isNotEmpty &&
            !_firstCollectedColorsAlertShown,
        listener: (context, state) {
          _firstCollectedColorsAlertShown = true;
          showCustomDialog(
            context: context,
            icon: Assets.icons.gallery.designImage(
              height: 28,
              width: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            message:
                'You have collected your first colors! You can check out all your photos and collected colors in the gallery.',
            onDismiss: () {},
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom layer: image viewer preloads whilst video plays
            Positioned.fill(
              child:  ImageCarouselNew()
                  // ImageViewerScreen(
                  //   onThemeToggle: onThemeToggle,
                  //   onShareTap: onShareTap,
                  //   onOpenGalleryRoute: onOpenGalleryRoute,
                  //   videoComplete: _videoComplete,
                  // ),
            ),
            // Transform.scale(
            //   scale: 1.12,
            //   child: Transform.translate(
            //     offset: Offset(0, -20),
            //     child: IgnorePointer(
            //       ignoring: _videoComplete,
            //       child: AnimatedOpacity(
            //         opacity: _videoComplete ? 0 : 1,
            //         duration: _fadeDuration,
            //         child: ColoredBox(
            //           color: Colors.black,
            //           child: Center(
            //             child: widget.overlayBuilder != null
            //                 ? widget.overlayBuilder!(_onVideoComplete)
            //                 : VideoView(onVideoComplete: _onVideoComplete),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
