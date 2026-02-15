import 'package:flutter/material.dart';
import 'package:utils/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:tts_service/tts_service.dart';

import '../../cubit/fakes/fake_tts_service.dart';
import '../../data/fakes/fake_image_analysis_service.dart';
import '../../data/fakes/fake_image_remote_datasource.dart';

const _testOverlayKey = Key('test_overlay');
const _bottomLayerKey = Key('test_bottom_layer');
const _firstContentKey = Key('first_content');

void main() {
  late GetIt testGetIt;
  late FakeImageRemoteDatasource fakeDatasource;
  late FakeImageAnalysisService fakeAnalysisService;
  late FakeTtsService fakeTtsService;

  setUp(() {
    testGetIt = GetIt.asNewInstance();
    fakeDatasource = FakeImageRemoteDatasource(
      urlsToReturn: [
        'https://test.com/1',
        'https://test.com/2',
        'https://test.com/3',
        'https://test.com/4',
        'https://test.com/5',
      ],
    );
    fakeAnalysisService = FakeImageAnalysisService(
      resultsToReturn: [
        Success(testImage('uid1', 'sig1')),
        Success(testImage('uid2', 'sig2')),
        Success(testImage('uid3', 'sig3')),
        Success(testImage('uid4', 'sig4')),
        Success(testImage('uid5', 'sig5')),
      ],
    );
    fakeTtsService = FakeTtsService();

    testGetIt.registerSingleton<ImageRemoteDatasource>(fakeDatasource);
    testGetIt.registerSingleton<ImageAnalysisService>(fakeAnalysisService);
    testGetIt.registerSingleton<AbstractTtsService>(fakeTtsService);
    testGetIt.registerLazySingleton<ImageRepository>(
      () => ImageRepositoryImpl(
        remoteDatasource: testGetIt<ImageRemoteDatasource>(),
        imageAnalysisService: testGetIt<ImageAnalysisService>(),
      ),
    );
    testGetIt.registerFactory<ImageViewerBloc>(
      () => ImageViewerBloc(imageRepository: testGetIt<ImageRepository>()),
    );
    testGetIt.registerFactory<TtsCubit>(
      () => TtsCubit(ttsService: testGetIt<AbstractTtsService>()),
    );
    testGetIt.registerFactory<FavouritesCubit>(() => FavouritesCubit());
    testGetIt.registerFactory<CollectedColorsCubit>(() => CollectedColorsCubit());
    testGetIt.registerFactory<ScrollDirectionCubit>(() => ScrollDirectionCubit());
  });

  tearDown(() async {
    await testGetIt.reset();
    fakeTtsService.dispose();
  });

  /// When [useOrchestrationLayer] is true, uses a bloc-driven layer that shows
  /// first content when fetch completes (avoids shaders). Else uses a stub.
  Widget buildTestFlow({
    Widget Function(VoidCallback onVideoComplete)? overlayBuilder,
    bool useOrchestrationLayer = false,
  }) {
    return MaterialApp(
      home: ImageViewerFlow(
        getIt: testGetIt,
        onThemeToggle: noop,
        bottomLayer: useOrchestrationLayer
            ? BlocBuilder<ImageViewerBloc, ImageViewerState>(
                builder: (context, state) {
                  final hasContent = state.visibleImages.isNotEmpty;
                  return ColoredBox(
                    key: hasContent ? _firstContentKey : _bottomLayerKey,
                    color: hasContent ? Colors.green : Colors.grey,
                    child: const SizedBox.expand(),
                  );
                },
              )
            : ColoredBox(
                key: _bottomLayerKey,
                color: Colors.grey,
                child: const SizedBox.expand(),
              ),
        overlayBuilder: overlayBuilder ??
            (onComplete) => GestureDetector(
                  key: _testOverlayKey,
                  onTap: onComplete,
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: Colors.black,
                    child: const SizedBox.expand(),
                  ),
                ),
      ),
    );
  }

  group('ImageViewerFlow overlay transition', () {
    testWidgets('VideoView initially visible, blocks pointer', (tester) async {
      await tester.pumpWidget(buildTestFlow());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(_testOverlayKey), findsOneWidget);

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(Transform),
          matching: find.byType(AnimatedOpacity),
        ).first,
      );
      expect(animatedOpacity.opacity, 1.0);

      final ignorePointer = tester.widget<IgnorePointer>(
        find.ancestor(
          of: find.byKey(_testOverlayKey),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, false);
    });

    testWidgets('after onVideoComplete, opacity animates to 0 and pointer is released',
        (tester) async {
      await tester.pumpWidget(buildTestFlow());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.byKey(_testOverlayKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(Transform),
          matching: find.byType(AnimatedOpacity),
        ).first,
      );
      expect(animatedOpacity.opacity, 0.0);

      final ignorePointer = tester.widget<IgnorePointer>(
        find.ancestor(
          of: find.byKey(_testOverlayKey),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, true);
    });

    testWidgets('ImageViewerScreen is present underneath throughout', (tester) async {
      await tester.pumpWidget(buildTestFlow());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(_bottomLayerKey), findsOneWidget);

      await tester.tap(find.byKey(_testOverlayKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      expect(find.byKey(_bottomLayerKey), findsOneWidget);
    });
  });

  group('Cold start → intro video → first content', () {
    testWidgets('validates real orchestration: overlay visible, fetch runs, '
        'first content appears, video complete reveals content', (tester) async {
      await tester.pumpWidget(buildTestFlow(useOrchestrationLayer: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Cold start: overlay (intro video) visible and blocks pointer
      expect(find.byKey(_testOverlayKey), findsOneWidget);
      final ignorePointerBefore = tester.widget<IgnorePointer>(
        find.ancestor(
          of: find.byKey(_testOverlayKey),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointerBefore.ignoring, false);

      // 2. Let fetch complete: repository stream → bloc emits → content appears
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(_firstContentKey), findsOneWidget);

      // 3. Simulate video complete (tap overlay)
      await tester.tap(find.byKey(_testOverlayKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      // 4. Overlay fades, pointer released, content revealed
      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(Transform),
          matching: find.byType(AnimatedOpacity),
        ).first,
      );
      expect(animatedOpacity.opacity, 0.0);

      final ignorePointerAfter = tester.widget<IgnorePointer>(
        find.ancestor(
          of: find.byKey(_testOverlayKey),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointerAfter.ignoring, true);
      expect(find.byKey(_firstContentKey), findsOneWidget);
    });
  });
}

ImageModel testImage(String uid, String pixelSignature) => ImageModel(
      uid: uid,
      title: 't',
      description: 'd',
      isFavourite: false,
      url: 'https://example.com/$uid',
      colorPalette: const [Color(0xFF000000)],
      localPath: '',
      pixelSignature: pixelSignature,
    );
