import 'package:flutter/material.dart';
import 'package:image_analysis_service/image_analysis_service.dart';

const int imageViewerSlotCount = 5;
const int imageViewerMinColorsForShader = 4;

const List<Color> imageViewerFallbackPalette = [
  Color(0xFF6B4E9D),
  Color(0xFF4A47A3),
  Color(0xFF1E88E5),
];

/// Ensures [colors] has at least [imageViewerMinColorsForShader] entries.
List<Color> ensureMinColors(List<Color> colors) {
  if (colors.length >= imageViewerMinColorsForShader) return colors;
  if (colors.isEmpty) {
    return ensureMinColors(List.of(imageViewerFallbackPalette));
  }
  final out = List<Color>.from(colors);
  while (out.length < imageViewerMinColorsForShader) {
    out.add(out[out.length % colors.length]);
  }
  return out;
}

/// Produces [imageViewerSlotCount] colors by picking from each image per slot.
/// [ratio] maps slot index to image index.
List<Color> computeBlendedColors(List<ImageModel> images, List<int> ratio) {
  if (images.isEmpty) {
    return ensureMinColors(List.of(imageViewerFallbackPalette));
  }
  final result = <Color>[];
  for (var i = 0; i < imageViewerSlotCount; i++) {
    final imageIndex = (i < ratio.length ? ratio[i] : 0).clamp(
      0,
      images.length - 1,
    );
    final palette = images[imageIndex].colorPalette;
    final colorIndex = palette.isEmpty ? 0 : i % palette.length;
    result.add(
      palette.isEmpty
          ? imageViewerFallbackPalette[colorIndex % imageViewerFallbackPalette.length]
          : palette[colorIndex],
    );
  }
  return result;
}
