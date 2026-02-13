import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/domain/exceptions/image_viewer_exceptions.dart';
import 'package:image_viewer/src/domain/repositories/image_repository.dart';

import 'image_viewer_event.dart';
import 'image_viewer_state.dart';

class ImageViewerBloc extends Bloc<ImageViewerEvent, ImageViewerState> {
  ImageViewerBloc({required ImageRepository imageRepository})
    : _imageRepository = imageRepository,
      super(ImageViewerState.empty()) {
    on<ImageViewerFetchRequested>(_onFetchRequested);
    on<UpdateSelectedImage>(_updateSelectedImage);
    on<AnotherImageEvent>(_anotherImageEvent);
    on<ImageFavourited>(_onImageFavourited);
    on<ErrorDismissed>(_onErrorDismissed);
    on<CarouselControllerRegistered>(_onCarouselControllerRegistered);
    on<CarouselControllerUnregistered>(_onCarouselControllerUnregistered);
  }

  final ImageRepository _imageRepository;

  Future<void> _onFetchRequested(
    ImageViewerFetchRequested event,
    Emitter<ImageViewerState> emit,
  ) async {
    final existingImages = state.visibleImages;

    final isFirstLoad = existingImages.isEmpty;
    try {
      var allImages = List<ImageModel>.from(existingImages);
      if (isFirstLoad) {
        await for (final image in _imageRepository.runImageRetrieval(
          count: event.count,
          existingImages: existingImages,
        )) {
          allImages = [...allImages, image];
        
          emit(
            state.copyWith(
              loadingType: allImages.length != event.count
                  ? ViewerLoadingType.background
                  : ViewerLoadingType.none,
              fetchedImages: allImages.sublist(1, allImages.length),
              visibleImages: [allImages.first],
              selectedImage: allImages.first,
            ),
          );
        }
      } else {
        emit(state.copyWith(loadingType: event.loadingType));
        final newImages = await _imageRepository
            .runImageRetrieval(
              count: event.count,
              existingImages: [...state.visibleImages, ...state.fetchedImages],
            )
            .toList();

        if (_shouldAddFetchedAndNavigate(state, event, newImages)) {
          _emitFetchedWithAddAndNavigate(emit, state, newImages);
        } else {
          _emitFetchedOnly(emit, state, newImages);
        }
      }
    } on NoMoreImagesException {
      emit(
        state.copyWith(
          errorType: (event.loadingType == ViewerLoadingType.manual)
              ? ViewerErrorType.noMoreImages
              : null,
          loadingType: ViewerLoadingType.none,
        ),
      );
    } catch (e, _) {
      emit(
        state.copyWith(
          errorType: ViewerErrorType.unableToFetchImage,
          loadingType: ViewerLoadingType.none,
        ),
      );
    }
  }

  void _anotherImageEvent(event, emit) {
    if (state.fetchedImages.isNotEmpty) {
    
      List<ImageModel> currentlyVisible = List.from(state.visibleImages);
      currentlyVisible.add(state.fetchedImages.first);
      List<ImageModel> fetchedImages = List.from(state.fetchedImages);
      fetchedImages.removeAt(0);

      emit(
        state.copyWith(
          visibleImages: currentlyVisible,
          fetchedImages: fetchedImages,
        ),
      );

      _navigateCarousel();
    } else {
      if (state.loadingType == ViewerLoadingType.none) {
        add(
          const ImageViewerFetchRequested(
            count: 3,
            loadingType: ViewerLoadingType.manual,
          ),
        );
      }
    }
  }

  void _onErrorDismissed(ErrorDismissed event, Emitter<ImageViewerState> emit) {
    emit(state.copyWith(errorType: ViewerErrorType.none));
  }

  void _onCarouselControllerRegistered(
    CarouselControllerRegistered event,
    Emitter<ImageViewerState> emit,
  ) {
    emit(state.copyWith(carouselController: event.controller));
  }

  void _onCarouselControllerUnregistered(
    CarouselControllerUnregistered event,
    Emitter<ImageViewerState> emit,
  ) {
    emit(state.copyWith(clearCarouselController: true));
  }

  void _updateSelectedImage(
    UpdateSelectedImage event,
    Emitter<ImageViewerState> emit,
  ) {
    emit(state.copyWith(selectedImage: event.image));
  }

  void _onImageFavourited(
    ImageFavourited event,
    Emitter<ImageViewerState> emit,
  ) {
    final index = state.visibleImages.indexWhere(
      (i) => i.uid == event.image.uid,
    );
    if (index < 0) return;
    final toggled = event.image.copyWith(isFavourite: !event.image.isFavourite);
    final newImages = [
      ...state.visibleImages.sublist(0, index),
      toggled,
      ...state.visibleImages.sublist(index + 1),
    ];

    emit(state.copyWith(visibleImages: newImages));
  }

  void _navigateCarousel({int? target}) {
    final ctrl = state.carouselController;
    if (ctrl != null && ctrl.hasClients) {
      final targetPage = target ?? state.visibleImages.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ctrl.hasClients) {
          ctrl.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  bool _isOnLastPage(ImageViewerState s) =>
      s.visibleImages.isNotEmpty && s.selectedImage == s.visibleImages.last;

  bool _shouldAddFetchedAndNavigate(
    ImageViewerState s,
    ImageViewerFetchRequested event,
    List<ImageModel> newImages,
  ) =>
      event.loadingType == ViewerLoadingType.manual &&
      _isOnLastPage(s) &&
      newImages.isNotEmpty;

  void _emitFetchedWithAddAndNavigate(
    Emitter<ImageViewerState> emit,
    ImageViewerState current,
    List<ImageModel> newImages,
  ) {
    final newVisible = [...current.visibleImages, newImages.first];
    emit(
      current.copyWith(
        visibleImages: newVisible,
        fetchedImages: newImages.sublist(1),
        selectedImage: newImages.first,
        loadingType: ViewerLoadingType.none,
      ),
    );
    _navigateCarousel(target: newVisible.length - 1);
  }

  void _emitFetchedOnly(
    Emitter<ImageViewerState> emit,
    ImageViewerState current,
    List<ImageModel> newImages,
  ) {
    emit(
      current.copyWith(
        fetchedImages: newImages,
        loadingType: ViewerLoadingType.none,
      ),
    );
  }
}
