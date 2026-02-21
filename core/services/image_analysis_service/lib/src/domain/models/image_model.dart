import 'dart:typed_data';
import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_model.freezed.dart';

@freezed
abstract class ImageModel with _$ImageModel {
  const ImageModel._();

  /// Added: All fields as per chatgpt_image_analysis_pipeline.dart (lines 50-61)
  const factory ImageModel({
    required String uid,
    required String title,
    required String description,
    required bool isFavourite,
    required String url,
    required List<Color> colorPalette,
    required String localPath,
    Uint8List? byteList,
    required String pixelSignature,
    // New fields corresponding to GPT image pipeline
    required String founderName,
    required String founderDescription,
    required String description2,
    required String hypeBuildingTagline1,
    required String hypeBuildingTagline2,
    required String hypeBuildingTagline3,
    required String hypeBuildingTagline4,
    required String hypeBuildingTagline5,
  }) = _ImageModel;

  /// Contrast ratio threshold (WCAG AAA). Minimum 7:1 for accessibility.
  static const double _minContrastRatio = 7.0;

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  static double _contrastRatio(Color lighter, Color darker) {
    final l1 = lighter.computeLuminance() + 0.05;
    final l2 = darker.computeLuminance() + 0.05;
    return l1 / l2;
  }

  /// Adjusts lightest toward white and darkest toward black until contrast >= 7:1.
  (Color, Color) _contrastingPair() {
    final lightest = colorPalette.reduce(
      (a, b) => a.computeLuminance() >= b.computeLuminance() ? a : b,
    );
    var light = lightest;
    var dark = colorPalette.reduce(
      (a, b) => a.computeLuminance() <= b.computeLuminance() ? a : b,
    );
    for (var i = 0; i < 50 && _contrastRatio(light, dark) < _minContrastRatio; i++) {
      light = Color.lerp(light, _white, 0.15)!;
      dark = Color.lerp(dark, _black, 0.15)!;
    }
    return (light, dark);
  }

  /// Lightest color from the palette (highest luminance).
  /// When contrast < 7:1, shifts toward white until met.
  Color get lightestColor {
    if (colorPalette.isEmpty) return _white;
    return _contrastingPair().$1;
  }

  /// Darkest color from the palette (lowest luminance).
  /// When contrast < 7:1, shifts toward black until met.
  Color get darkestColor {
    if (colorPalette.isEmpty) return _black;
    return _contrastingPair().$2;
  }

  factory ImageModel.empty() => ImageModel(
        uid: '',
        title: '',
        description: '',
        isFavourite: false,
        url: '',
        colorPalette: const [],
        localPath: '',
        byteList: null,
        pixelSignature: '',
        founderName: '',
        founderDescription: '',
        description2: '',
        hypeBuildingTagline1: '',
        hypeBuildingTagline2: '',
        hypeBuildingTagline3: '',
        hypeBuildingTagline4: '',
        hypeBuildingTagline5: '',
      );
}