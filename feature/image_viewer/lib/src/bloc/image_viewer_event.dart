import 'package:flutter/material.dart';
import 'package:image_analysis_service/src/domain/models/image_model.dart';
import 'package:image_viewer/image_viewer.dart';

sealed class ImageViewerEvent {
  const ImageViewerEvent();
}

final class ImageViewerFetchRequested extends ImageViewerEvent {
  final int count; 
  final ViewerLoadingType loadingType; 
  const ImageViewerFetchRequested({this.count = 5, this.loadingType = ViewerLoadingType.background});
}

final class UpdateSelectedImage extends ImageViewerEvent {
  final ImageModel image;
  const UpdateSelectedImage({required this.image});
}

final class AnotherImageEvent extends ImageViewerEvent {
  const AnotherImageEvent();
}

/// Cancels an in-flight image fetch (manual or background).
final class FetchCancelled extends ImageViewerEvent {
  const FetchCancelled();
}

final class ErrorDismissed extends ImageViewerEvent {
  const ErrorDismissed();
}

final class CarouselControllerRegistered extends ImageViewerEvent {
  final PageController controller;
  const CarouselControllerRegistered({required this.controller});
}

final class CarouselControllerUnregistered extends ImageViewerEvent {
  const CarouselControllerUnregistered();
}