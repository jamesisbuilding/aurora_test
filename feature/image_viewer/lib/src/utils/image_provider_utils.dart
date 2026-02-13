import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_analysis_service/image_analysis_service.dart';

/// Creates an [ImageProvider] from [ImageModel] for use as a decoration background.
/// Prefers localPath, then byteList, then network URL. Returns null if none available.
ImageProvider? imageProviderForImage(ImageModel? image) {
  if (image == null) return null;
  if (image.localPath.isNotEmpty) {
    return FileImage(File(image.localPath));
  }
  if (image.byteList != null && image.byteList!.isNotEmpty) {
    return MemoryImage(image.byteList!);
  }
  if (image.url.isNotEmpty && isNetworkURL(image.url)) {
    return CachedNetworkImageProvider(image.url);
  }
  return null;
}
