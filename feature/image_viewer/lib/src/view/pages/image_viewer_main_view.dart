import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:image_viewer/src/utils/image_provider_utils.dart';
import 'package:image_viewer/src/utils/image_viewer_color_utils.dart';
import 'package:image_viewer/src/view/widgets/alerts/custom_dialog.dart';
import 'package:image_viewer/src/view/widgets/background/image_viewer_background.dart';
import 'package:image_viewer/src/view/widgets/bloc_state_debug_overlay.dart';
import 'package:image_viewer/src/view/widgets/control_bar/control_bar.dart';
import 'package:image_viewer/src/view/widgets/image_carousel.dart';
import 'package:image_viewer/src/view/widgets/loading/background_loading_indicator.dart';

part 'carousel_scope.dart';
part 'image_viewer_content.dart';

/// Expects [BlocProvider<ImageViewerBloc>] from an ancestor (e.g. app router).
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({
    super.key,
    required this.onThemeToggle,
    this.onShareTap,
    this.videoComplete = true,
  });

  final VoidCallback onThemeToggle;
  final void Function(ImageModel?, {Uint8List? screenshotBytes})? onShareTap;

  /// When false, startup errors (no visible images) are suppressed until the
  /// intro video completes. Defaults to true for tests/direct usage.
  final bool videoComplete;

  @override
  Widget build(BuildContext context) {
    return _ImageViewerContent(
      onThemeToggle: onThemeToggle,
      onShareTap: onShareTap,
      videoComplete: videoComplete,
    );
  }
}
