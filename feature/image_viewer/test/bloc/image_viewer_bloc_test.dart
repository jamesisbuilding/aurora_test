import 'dart:async' show Completer, StreamSubscription, TimeoutException, StreamController;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:image_viewer/src/domain/exceptions/image_viewer_exceptions.dart';
import 'package:mocktail/mocktail.dart';

import 'image_viewer_bloc_test_utils.dart';

void main() {
  late MockImageRepository mockRepository;
  late ImageViewerBloc bloc;

  setUp(() {
    mockRepository = MockImageRepository();
    bloc = ImageViewerBloc(imageRepository: mockRepository);
  });

  tearDown(() => bloc.close());

  /// Waits until bloc emits a state matching [predicate], then returns collected states.
  Future<List<ImageViewerState>> collectUntil(
    ImageViewerBloc b,
    bool Function(ImageViewerState) predicate, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final states = <ImageViewerState>[];
    final completer = Completer<void>();
    late StreamSubscription<ImageViewerState> sub;
    sub = b.stream.listen((s) {
      states.add(s);
      if (predicate(s)) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future.timeout(timeout);
    return states;
  }

  group('ImageViewerBloc fetch + duplicate guard', () {
    test('first load sets visibleImages + selectedImage correctly', () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.value(_image('uid1', 'sig1')));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.background,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first.loadingType, ViewerLoadingType.background);

      final firstImageState = states.firstWhere(
        (s) => s.visibleImages.isNotEmpty,
        orElse: () => states.last,
      );
      expect(firstImageState.visibleImages.length, 1);
      expect(firstImageState.visibleImages.first.uid, 'uid1');
      expect(firstImageState.selectedImage, firstImageState.visibleImages.first);

      expect(states.last.loadingType, ViewerLoadingType.none);

      verify(() => mockRepository.runImageRetrieval(
            count: 1,
            existingImages: <ImageModel>[],
          )).called(1);
    });

    test('manual fetch while on last page appends and navigates path',
        () async {
      final img1 = _image('uid1', 'sig1');
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.value(_image('uid2', 'sig2')));

      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [img1],
        fetchedImages: [],
        selectedImage: img1,
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.manual,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none && s.visibleImages.length == 2,
      );

      final appendedState = states.firstWhere(
        (s) => s.visibleImages.length == 2,
        orElse: () => states.last,
      );
      expect(appendedState.visibleImages.last.uid, 'uid2');
      expect(appendedState.selectedImage, appendedState.visibleImages.last);
      expect(appendedState.loadingType, ViewerLoadingType.none);

      bloc.close();
    });

    test('duplicate signatures are skipped via reservation guard', () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer(
        (_) => Stream.fromIterable([
          _image('uid1', 'sig1'),
          _image('uid2', 'sig1'),
          _image('uid3', 'sig2'),
        ]),
      );

      bloc.add(const ImageViewerFetchRequested(
        count: 3,
        loadingType: ViewerLoadingType.background,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      final firstImageState = states.firstWhere(
        (s) => s.visibleImages.isNotEmpty,
        orElse: () => states.last,
      );
      expect(firstImageState.visibleImages.length, 1);
      expect(firstImageState.visibleImages.first.uid, 'uid1');

      final withFetched = states.firstWhere(
        (s) => s.fetchedImages.isNotEmpty,
        orElse: () => states.last,
      );
      expect(withFetched.fetchedImages.length, 1);
      expect(withFetched.fetchedImages.first.uid, 'uid3');
    });

    test('NoMoreImagesException only shows manual-mode errors', () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.error(NoMoreImagesException()));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.manual,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.last.loadingType, ViewerLoadingType.none);
      expect(states.last.errorType, ViewerErrorType.noMoreImages);
    });

    test('NoMoreImagesException during background fetch with images does NOT show error',
        () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.error(NoMoreImagesException()));

      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.background,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.last.loadingType, ViewerLoadingType.none);
      expect(states.last.errorType, ViewerErrorType.none);
    });

    test('NoMoreImagesException during background fetch with NO visible images DOES show error',
        () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.error(NoMoreImagesException()));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.background,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.last.loadingType, ViewerLoadingType.none);
      expect(states.last.errorType, ViewerErrorType.noMoreImages);
      expect(states.last.visibleImages, isEmpty);
    });

    test('TimeoutException only shows manual-mode errors', () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.error(TimeoutException('test')));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.manual,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.last.loadingType, ViewerLoadingType.none);
      expect(states.last.errorType, ViewerErrorType.fetchTimeout);
    });

    test('TimeoutException during background fetch with images does NOT show error',
        () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.error(TimeoutException('test')));

      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.background,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(bloc.state.errorType, ViewerErrorType.none);
    });

    test('TimeoutException during background fetch with NO visible images DOES show error',
        () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.error(TimeoutException('test')));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.background,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.last.errorType, ViewerErrorType.fetchTimeout);
      expect(states.last.visibleImages, isEmpty);
    });

    test('generic error during background fetch with NO visible images DOES show error',
        () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.error(Exception('Network error')));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.background,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.last.errorType, ViewerErrorType.unableToFetchImage);
      expect(states.last.visibleImages, isEmpty);
    });

    test('background fetch completion resets loading to none', () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer(
        (_) => Stream.fromIterable([
          _image('uid1', 'sig1'),
          _image('uid2', 'sig2'),
        ]),
      );

      bloc.add(const ImageViewerFetchRequested(
        count: 2,
        loadingType: ViewerLoadingType.background,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.last.loadingType, ViewerLoadingType.none);
      expect(states.last.fetchedImages.length, 1);
    });
  });

  group('Fetch trigger behavior (Another / prefetch)', () {
    test('AnotherImageEvent with exactly 1 prefetched: consumes and triggers background fetch',
        () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.value(_image('uid4', 'sig4')));

      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [_image('uid2', 'sig2')],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const AnotherImageEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.visibleImages.length, 2);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      verify(() => mockRepository.runImageRetrieval(
            count: 5,
            existingImages: any(named: 'existingImages'),
          )).called(1);
      bloc.close();
    });

    test('AnotherImageEvent with 2+ prefetched: consumes first, no fetch when 2+ remain',
        () async {
      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [
          _image('uid2', 'sig2'),
          _image('uid3', 'sig3'),
          _image('uid4', 'sig4'),
        ],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const AnotherImageEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.visibleImages.length, 2);
      expect(bloc.state.fetchedImages.length, 2);

      verifyNever(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          ));
    });

    test('AnotherImageEvent with no prefetched and loading none: triggers manual fetch',
        () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.value(_image('uid2', 'sig2')));

      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const AnotherImageEvent());

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );
      expect(states.any((s) => s.loadingType == ViewerLoadingType.manual), true);
      expect(states.last.visibleImages.length, 2);

      verify(() => mockRepository.runImageRetrieval(
            count: 5,
            existingImages: any(named: 'existingImages'),
          )).called(1);
      bloc.close();
    });

    test('AnotherImageEvent with no prefetched and loading background: switches to manual, no new fetch',
        () async {
      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.background,
      ));

      bloc.add(const AnotherImageEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.loadingType, ViewerLoadingType.manual);
      verifyNever(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          ));
    });

    test('ImageViewerFetchRequested with default params triggers background prefetch',
        () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer(
        (_) => Stream.fromIterable([
          _image('uid1', 'sig1'),
          _image('uid2', 'sig2'),
          _image('uid3', 'sig3'),
        ]),
      );

      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [_image('uid2', 'sig2')],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const ImageViewerFetchRequested());

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      verify(() => mockRepository.runImageRetrieval(
            count: 5,
            existingImages: any(named: 'existingImages'),
          )).called(1);
      expect(states.last.loadingType, ViewerLoadingType.none);
      bloc.close();
    });
  });

  group('FetchCancelled', () {
    test('FetchCancelled during manual fetch cancels subscription and sets loadingType to none',
        () async {
      final neverCompleting = StreamController<ImageModel>();
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => neverCompleting.stream);

      bloc = ImageViewerBloc(imageRepository: mockRepository);
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.manual,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.loadingType, ViewerLoadingType.manual);

      bloc.add(const FetchCancelled());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.loadingType, ViewerLoadingType.none);
      bloc.close();
    });
  });

  group('Bloc handlers coverage', () {
    test('ErrorDismissed clears errorType', () async {
      bloc.emit(ImageViewerState(
        visibleImages: [_image('uid1', 'sig1')],
        fetchedImages: [],
        selectedImage: _image('uid1', 'sig1'),
        loadingType: ViewerLoadingType.none,
        errorType: ViewerErrorType.unableToFetchImage,
      ));

      bloc.add(const ErrorDismissed());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.errorType, ViewerErrorType.none);
    });

    test('CarouselControllerRegistered and Unregistered update state',
        () async {
      final controller = PageController();

      bloc.add(CarouselControllerRegistered(controller: controller));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.carouselController, controller);

      bloc.add(const CarouselControllerUnregistered());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.carouselController, isNull);
    });

    test('generic catch emits unableToFetchImage for manual load', () async {
      when(() => mockRepository.runImageRetrieval(
            count: any(named: 'count'),
            existingImages: any(named: 'existingImages'),
          )).thenAnswer((_) => Stream.error(Exception('Network error')));

      bloc.add(const ImageViewerFetchRequested(
        count: 1,
        loadingType: ViewerLoadingType.manual,
      ));

      final states = await collectUntil(
        bloc,
        (s) => s.loadingType == ViewerLoadingType.none,
      );

      expect(states.last.errorType, ViewerErrorType.unableToFetchImage);
    });

    test('releaseReservedSignature removes in-flight signature', () {
      expect(bloc.tryReserveSignature('sig1'), true);
      bloc.releaseReservedSignature('sig1');
      expect(bloc.tryReserveSignature('sig1'), true);
    });

    test('releaseReservedSignature does nothing for empty signature', () {
      bloc.releaseReservedSignature('');
    });
  });
}

ImageModel _image(String uid, String pixelSignature) => ImageModel(
      uid: uid,
      title: 't',
      description: 'd',
      isFavourite: false,
      url: 'https://example.com/$uid',
      colorPalette: const [Color(0xFF000000)],
      localPath: '',
      pixelSignature: pixelSignature,
    );
