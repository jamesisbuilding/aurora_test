part of 'image_viewer_bloc.dart';

extension ImageBlocHandlers on ImageViewerBloc {
  void _onFetchCancelled(FetchCancelled event, Emitter<ImageViewerState> emit) {
    _fetchSubscription?.cancel();
    _fetchSubscription = null;
    if (_fetchCancelCompleter != null && !_fetchCancelCompleter!.isCompleted) {
      _fetchCancelCompleter!.complete();
    }
    _fetchCancelCompleter = null;
    if (state.loadingType != ViewerLoadingType.none) {
      emit(state.copyWith(loadingType: ViewerLoadingType.none));
    }
  }

  Future<void> _onFetchRequested(
    ImageViewerFetchRequested event,
    Emitter<ImageViewerState> emit,
  ) async {
    final bool isFirstLoad = state.visibleImages.isEmpty;
    bool isFirstArrivalFromStream = true;

    emit(state.copyWith(loadingType: event.loadingType));

    seedAcceptedSignatures([
      ...state.visibleImages.map((e) => e.pixelSignature),
      ...state.fetchedImages.map((e) => e.pixelSignature),
    ]);

    final existingSignatures = {
      ...state.visibleImages
          .map((e) => e.pixelSignature)
          .where((s) => s.isNotEmpty),
      ...state.fetchedImages
          .map((e) => e.pixelSignature)
          .where((s) => s.isNotEmpty),
    };
    

    final streamCompleter = Completer<void>();
    _fetchCancelCompleter = Completer<void>();
    _fetchSubscription = _imageRepository
        .runImageRetrieval(
          count: event.count,
          existingImages: [...state.visibleImages, ...state.fetchedImages],
        )
        .listen(
          (image) {
            if (streamCompleter.isCompleted) return;
            final sig = image.pixelSignature;
            if (sig.isEmpty || existingSignatures.contains(sig)) {
              if (kDebugMode && sig.isNotEmpty) {
                debugPrint('[Bloc] Skipping duplicate pixelSignature: $sig');
              }
              return;
            }
            if (!tryReserveSignature(sig)) {
              if (kDebugMode) {
                debugPrint(
                    '[Bloc] Skipping reserved/accepted pixelSignature: $sig');
              }
              return;
            }
            existingSignatures.add(sig);

            if (isFirstLoad && isFirstArrivalFromStream) {
              emit(
                state.copyWith(
                  visibleImages: [image],
                  selectedImage: image,
                  loadingType: ViewerLoadingType.background,
                ),
              );
            } else if (state.loadingType == ViewerLoadingType.manual &&
                _isOnLastPage(state) &&
                isFirstArrivalFromStream) {
              final updatedVisible = [...state.visibleImages, image];
              emit(
                state.copyWith(
                  visibleImages: updatedVisible,
                  selectedImage: image,
                  loadingType: ViewerLoadingType.none,
                ),
              );
              _navigateCarousel(target: updatedVisible.length - 1);
            } else {
              emit(state.copyWith(fetchedImages: [...state.fetchedImages, image]));
            }

            acceptReservedSignature(sig);
            isFirstArrivalFromStream = false;
          },
          onError: (e, s) {
            if (!streamCompleter.isCompleted) streamCompleter.completeError(e, s);
          },
          onDone: () {
            if (!streamCompleter.isCompleted) streamCompleter.complete();
          },
          cancelOnError: false,
        );

    try {
      await Future.any([
        streamCompleter.future,
        _fetchCancelCompleter!.future,
      ]);
      _fetchSubscription = null;
      _fetchCancelCompleter = null;
      if (!streamCompleter.isCompleted) {
        return;
      }
      emit(state.copyWith(loadingType: ViewerLoadingType.none));
    } on NoMoreImagesException {
      // Surface errors when user is actively waiting (manual) or when we have
      // no visible images (initial/background fetch failure - user needs feedback).
      final isManualAtCatch = state.loadingType == ViewerLoadingType.manual;
      final hasNoVisibleImages = state.visibleImages.isEmpty;
      emit(
        state.copyWith(
          loadingType: ViewerLoadingType.none,
          errorType: (isManualAtCatch || hasNoVisibleImages)
              ? ViewerErrorType.noMoreImages
              : null,
        ),
      );
    } on TimeoutException {
      final isManualAtCatch = state.loadingType == ViewerLoadingType.manual;
      final hasNoVisibleImages = state.visibleImages.isEmpty;
      if (isManualAtCatch || hasNoVisibleImages) {
        emit(
          state.copyWith(
            errorType: ViewerErrorType.fetchTimeout,
            loadingType: ViewerLoadingType.none,
          ),
        );
      }
    } catch (e) {
      final isManualAtCatch = state.loadingType == ViewerLoadingType.manual;
      final hasNoVisibleImages = state.visibleImages.isEmpty;
      if (isManualAtCatch || hasNoVisibleImages) {
        emit(
          state.copyWith(
            errorType: ViewerErrorType.unableToFetchImage,
            loadingType: ViewerLoadingType.none,
          ),
        );
      }
    } finally {
      _inFlightSignatures.clear();
    }
  }

  void _anotherImageEvent(event, emit) {
    if (state.fetchedImages.isNotEmpty) {
      if (state.fetchedImages.length == 1) {
        add(
          const ImageViewerFetchRequested(
            count: 5,
            loadingType: ViewerLoadingType.background,
          ),
        );
      }
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
            count: 5,
            loadingType: ViewerLoadingType.manual,
          ),
        );
      } else if (state.loadingType == ViewerLoadingType.background) {
        emit(state.copyWith(loadingType: ViewerLoadingType.manual));
      }
    }
  }

  // --- Helper Methods ---

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
}
