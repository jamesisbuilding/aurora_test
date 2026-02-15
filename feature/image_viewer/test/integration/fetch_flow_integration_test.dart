import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';
import '../data/fakes/fake_image_analysis_service.dart';
import '../data/fakes/fake_image_remote_datasource.dart';

/// Fetch flow end-to-end integration test.
/// Bloc + ImageRepositoryImpl + fakes. Validates orchestration and duplicate logic.
void main() {
  late ImageRepository repository;
  late FakeImageRemoteDatasource fakeDatasource;
  late FakeImageAnalysisService fakeAnalysis;
  late ImageViewerBloc bloc;

  ImageModel img(String uid, String sig) => testImage(uid, sig);

  Future<List<ImageViewerState>> collectUntil(
    bool Function(ImageViewerState) predicate, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final states = <ImageViewerState>[];
    final completer = Completer<void>();
    StreamSubscription<ImageViewerState>? sub;
    sub = bloc.stream.listen((s) {
      states.add(s);
      if (predicate(s)) {
        sub?.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future.timeout(timeout);
    return states;
  }

  void assertNoDuplicateSignatures(ImageViewerState state) {
    final all = [...state.visibleImages, ...state.fetchedImages];
    final sigs = all.map((e) => e.pixelSignature).where((s) => s.isNotEmpty);
    final unique = sigs.toSet();
    expect(
      unique.length,
      sigs.length,
      reason: 'Duplicate signatures: $sigs',
    );
  }

  setUp(() {
    fakeDatasource = FakeImageRemoteDatasource(
      urlsToReturn: List.generate(
        20,
        (i) => 'https://test.com/$i',
      ),
    );
    fakeAnalysis = FakeImageAnalysisService(
      resultsToReturn: [
        for (var i = 0; i < 20; i++)
          Success(img('uid$i', 'sig$i')),
      ],
    );
    repository = ImageRepositoryImpl(
      remoteDatasource: fakeDatasource,
      imageAnalysisService: fakeAnalysis,
    );
    bloc = ImageViewerBloc(imageRepository: repository);
  });

  tearDown(() => bloc.close());

  group('Fetch flow end-to-end', () {
    test('initial fetch → swipe near-end prefetch → Another (queue exists vs empty) '
        '→ no duplicate signatures', () async {
      bloc.add(const ImageViewerFetchRequested(
        count: 5,
        loadingType: ViewerLoadingType.background,
      ));

      await collectUntil(
        (s) => s.loadingType == ViewerLoadingType.none,
        timeout: const Duration(seconds: 10),
      );

      expect(bloc.state.visibleImages.length, 1);
      expect(bloc.state.fetchedImages.length, 4);
      assertNoDuplicateSignatures(bloc.state);

      final initialSigs = {
        ...bloc.state.visibleImages.map((e) => e.pixelSignature),
        ...bloc.state.fetchedImages.map((e) => e.pixelSignature),
      };

      bloc.add(const ImageViewerFetchRequested(
        count: 5,
        loadingType: ViewerLoadingType.background,
      ));

      await collectUntil(
        (s) => s.loadingType == ViewerLoadingType.none,
        timeout: const Duration(seconds: 10),
      );

      expect(
        bloc.state.visibleImages.length + bloc.state.fetchedImages.length,
        greaterThanOrEqualTo(10),
      );
      assertNoDuplicateSignatures(bloc.state);
      for (final sig in initialSigs) {
        expect(
          bloc.state.visibleImages.any((e) => e.pixelSignature == sig) ||
              bloc.state.fetchedImages.any((e) => e.pixelSignature == sig),
          true,
        );
      }

      bloc.add(const AnotherImageEvent());
      await Future<void>.delayed(Duration.zero);
      assertNoDuplicateSignatures(bloc.state);

      bloc.add(const AnotherImageEvent());
      bloc.add(const AnotherImageEvent());
      await Future<void>.delayed(Duration.zero);
      assertNoDuplicateSignatures(bloc.state);
    });

    test('Another with prefetched queue: consumes without new fetch until queue=1',
        () async {
      bloc.emit(ImageViewerState(
        visibleImages: [img('u1', 's1')],
        fetchedImages: [img('u2', 's2'), img('u3', 's3'), img('u4', 's4')],
        selectedImage: img('u1', 's1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const AnotherImageEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.visibleImages.length, 2);
      expect(bloc.state.fetchedImages.length, 2);
      assertNoDuplicateSignatures(bloc.state);
      expect(fakeDatasource.callCount, 0);

      bloc.add(const AnotherImageEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.visibleImages.length, 3);
      expect(bloc.state.fetchedImages.length, 1);
      assertNoDuplicateSignatures(bloc.state);
      expect(fakeDatasource.callCount, 0);

      bloc.add(const AnotherImageEvent());
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(bloc.state.visibleImages.length, 4);
      expect(fakeDatasource.callCount, greaterThan(0));
      assertNoDuplicateSignatures(bloc.state);
    });

    test('Another with empty queue: triggers manual fetch', () async {
      bloc.emit(ImageViewerState(
        visibleImages: [img('u1', 's1')],
        fetchedImages: [],
        selectedImage: img('u1', 's1'),
        loadingType: ViewerLoadingType.none,
      ));

      bloc.add(const AnotherImageEvent());

      await collectUntil((s) => s.loadingType == ViewerLoadingType.none);

      expect(bloc.state.visibleImages.length, 2);
      assertNoDuplicateSignatures(bloc.state);
      expect(fakeDatasource.callCount, greaterThan(0));
    });

    test('duplicate signatures from repo are never surfaced in bloc state',
        () async {
      fakeAnalysis.reset(
        resultsToReturn: [
          Success(img('u1', 's1')),
          Success(img('u2', 's2')),
          Success(img('u3', 's3')),
          Success(img('u4', 's4')),
          Success(img('u5', 's5')),
          Success(img('u6', 's6')),
          Success(img('u7', 's7')),
          Success(img('u8', 's8')),
          Success(img('u9', 's9')),
          Success(img('u10', 's10')),
        ],
      );
      fakeDatasource.reset(
        urlsToReturn: [
          'https://a.com/1',
          'https://a.com/2',
          'https://a.com/3',
          'https://a.com/4',
          'https://a.com/5',
          'https://a.com/6',
          'https://a.com/7',
          'https://a.com/8',
          'https://a.com/9',
          'https://a.com/10',
        ],
      );

      bloc.add(const ImageViewerFetchRequested(
        count: 5,
        loadingType: ViewerLoadingType.background,
      ));

      await collectUntil((s) => s.loadingType == ViewerLoadingType.none);

      assertNoDuplicateSignatures(bloc.state);

      bloc.add(const ImageViewerFetchRequested(
        count: 5,
        loadingType: ViewerLoadingType.background,
      ));

      await collectUntil((s) => s.loadingType == ViewerLoadingType.none);

      assertNoDuplicateSignatures(bloc.state);
    });
  });
}
