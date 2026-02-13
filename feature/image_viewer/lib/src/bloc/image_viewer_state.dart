import 'package:flutter/material.dart';
import 'package:image_analysis_service/src/domain/models/image_model.dart';

enum ViewerLoadingType { none, manual, background }

enum ViewerErrorType {
  none(message: ''),
  unableToFetchImage(
    message:
        'Unable to fetch images. Please check your connection and try again.',
  ),
  noMoreImages(
    message:
        'Oops! It seems we\'re receiving a lot of duplicates now, so you may have gotten all the packages available!\nTry load some more or check out their descriptions.',
  );

  const ViewerErrorType({required this.message});

  final String message;
}

class ImageViewerState {
  final List<ImageModel> fetchedImages;
  final List<ImageModel> visibleImages;
  final ImageModel? selectedImage;
  final ViewerLoadingType loadingType;
  final ViewerErrorType errorType;
  final PageController? carouselController;

  ImageViewerState({
    required this.fetchedImages,
    required this.visibleImages,
    required this.selectedImage,
    this.loadingType = ViewerLoadingType.none,
    this.errorType = ViewerErrorType.none,
    this.carouselController,
  });

  factory ImageViewerState.empty() {
    return ImageViewerState(
      fetchedImages: <ImageModel>[],
      visibleImages: <ImageModel>[],
      selectedImage: null,
      loadingType: ViewerLoadingType.none,
      errorType: ViewerErrorType.none,
    );
  }

  ImageViewerState copyWith({
    List<ImageModel>? fetchedImages,
    List<ImageModel>? visibleImages,
    ImageModel? selectedImage,
    ViewerLoadingType? loadingType,
    ViewerErrorType? errorType,
    PageController? carouselController,
    bool clearCarouselController = false,
  }) {
    return ImageViewerState(
      fetchedImages: fetchedImages ?? this.fetchedImages,
      visibleImages: visibleImages ?? this.visibleImages,
      selectedImage: selectedImage ?? this.selectedImage,
      loadingType: loadingType ?? this.loadingType,
      errorType: errorType ?? this.errorType,
      carouselController: clearCarouselController
          ? null
          : (carouselController ?? this.carouselController),
    );
  }
}
