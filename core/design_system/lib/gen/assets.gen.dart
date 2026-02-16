// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsFontsGen {
  const $AssetsFontsGen();

  /// File path: assets/fonts/Raleway-Regular.ttf
  String get ralewayRegular =>
      'packages/design_system/assets/fonts/Raleway-Regular.ttf';

  /// File path: assets/fonts/YesevaOne-Regular.ttf
  String get yesevaOneRegular =>
      'packages/design_system/assets/fonts/YesevaOne-Regular.ttf';

  /// List of all assets
  List<String> get values => [ralewayRegular, yesevaOneRegular];
}

class $AssetsGifsGen {
  const $AssetsGifsGen();

  /// File path: assets/gifs/arrow_down.gif
  AssetGenImage get arrowDown =>
      const AssetGenImage('assets/gifs/arrow_down.gif');

  /// File path: assets/gifs/swipe.gif
  AssetGenImage get swipe => const AssetGenImage('assets/gifs/swipe.gif');

  /// File path: assets/gifs/touch.gif
  AssetGenImage get touch => const AssetGenImage('assets/gifs/touch.gif');

  /// List of all assets
  List<AssetGenImage> get values => [arrowDown, swipe, touch];
}

class $AssetsGraphicsGen {
  const $AssetsGraphicsGen();

  /// File path: assets/graphics/cloud-white.png
  AssetGenImage get cloudWhite =>
      const AssetGenImage('assets/graphics/cloud-white.png');

  /// List of all assets
  List<AssetGenImage> get values => [cloudWhite];
}

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/arrow-down-up.png
  AssetGenImage get arrowDownUp =>
      const AssetGenImage('assets/icons/arrow-down-up.png');

  /// File path: assets/icons/moon.png
  AssetGenImage get moon => const AssetGenImage('assets/icons/moon.png');

  /// File path: assets/icons/send.png
  AssetGenImage get send => const AssetGenImage('assets/icons/send.png');

  /// File path: assets/icons/star.png
  AssetGenImage get star => const AssetGenImage('assets/icons/star.png');

  /// File path: assets/icons/sun.png
  AssetGenImage get sun => const AssetGenImage('assets/icons/sun.png');

  /// File path: assets/icons/trash.png
  AssetGenImage get trash => const AssetGenImage('assets/icons/trash.png');

  /// List of all assets
  List<AssetGenImage> get values => [arrowDownUp, moon, send, star, sun, trash];
}

class $AssetsVideoGen {
  const $AssetsVideoGen();

  /// File path: assets/video/intro.mp4
  String get intro => 'packages/design_system/assets/video/intro.mp4';

  /// File path: assets/video/thumbnail.png
  AssetGenImage get thumbnail =>
      const AssetGenImage('assets/video/thumbnail.png');

  /// List of all assets
  List<dynamic> get values => [intro, thumbnail];
}

class Assets {
  const Assets._();

  static const String package = 'design_system';

  static const $AssetsFontsGen fonts = $AssetsFontsGen();
  static const $AssetsGifsGen gifs = $AssetsGifsGen();
  static const $AssetsGraphicsGen graphics = $AssetsGraphicsGen();
  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsVideoGen video = $AssetsVideoGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  static const String package = 'design_system';

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    @Deprecated('Do not specify package for a generated library asset')
    String? package = package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    @Deprecated('Do not specify package for a generated library asset')
    String? package = package,
  }) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => 'packages/design_system/$_assetName';
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
