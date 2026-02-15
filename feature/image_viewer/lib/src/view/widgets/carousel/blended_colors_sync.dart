import 'package:flutter/material.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/utils/image_viewer_color_utils.dart';

/// Syncs blended colors when bloc state changes (e.g. fetch, initial load).
class BlendedColorsSync extends StatefulWidget {
  const BlendedColorsSync({
    super.key,
    required this.selectedImage,
    required this.onSync,
  });

  final ImageModel selectedImage;
  final void Function(List<Color>) onSync;

  @override
  State<BlendedColorsSync> createState() => BlendedColorsSyncState();
}

class BlendedColorsSyncState extends State<BlendedColorsSync> {
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    _syncIfNeeded();
  }

  @override
  void didUpdateWidget(covariant BlendedColorsSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncIfNeeded();
  }

  void _syncIfNeeded() {
    if (_lastSyncedUid == widget.selectedImage.uid) return;
    _lastSyncedUid = widget.selectedImage.uid;
    final palette = widget.selectedImage.colorPalette;
    widget.onSync(
      ensureMinColors(
        palette.isNotEmpty
            ? List.of(palette)
            : List.of(imageViewerFallbackPalette),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
