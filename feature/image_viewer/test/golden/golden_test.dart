import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_viewer/image_viewer.dart';

import 'package:image_viewer/src/view/widgets/alerts/custom_dialog.dart';
import 'package:image_viewer/src/view/widgets/background/image_viewer_background.dart';
import 'package:image_viewer/src/view/widgets/control_bar/control_bar.dart';
import 'package:image_viewer/src/view/widgets/loading/background_loading_indicator.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_body.dart';
import 'package:mocktail/mocktail.dart';

import '../bloc/image_viewer_bloc_test_utils.dart';
import '../cubit/fakes/fake_tts_service.dart';
import '../data/fakes/fake_image_analysis_service.dart';

/// Golden snapshot tests for UI regression safety.
/// Run: `flutter test test/golden/golden_test.dart --update-goldens` to create/update.
/// CI skips golden tests (goldens gitignored); run locally after UI changes.
const _goldenSize = Size(430, 700);

void main() {
  late ImageViewerBloc imageViewerBloc;
  late TtsCubit ttsCubit;
  late FakeTtsService fakeTtsService;
  late MockImageRepository mockRepo;
  late FavouritesCubit favouritesCubit;
  late CollectedColorsCubit collectedColorsCubit;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = await Directory.systemTemp.createTemp('golden_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        if (call.method == 'getTemporaryDirectory') return tempDir.path;
        if (call.method == 'getApplicationSupportDirectory') return tempDir.path;
        if (call.method == 'getApplicationDocumentsDirectory') return tempDir.path;
        return null;
      },
    );
  });

  setUp(() {
    mockRepo = MockImageRepository();
    when(() => mockRepo.runImageRetrieval(
          count: any(named: 'count'),
          existingImages: any(named: 'existingImages'),
        )).thenAnswer((_) => Stream.empty());
    imageViewerBloc = ImageViewerBloc(imageRepository: mockRepo);
    fakeTtsService = FakeTtsService();
    ttsCubit = TtsCubit(ttsService: fakeTtsService);
    favouritesCubit = FavouritesCubit();
    collectedColorsCubit = CollectedColorsCubit();
  });

  tearDown(() {
    imageViewerBloc.close();
    ttsCubit.close();
    favouritesCubit.close();
    collectedColorsCubit.close();
    fakeTtsService.dispose();
  });

  /// Pumps with fixed duration; avoids pumpAndSettle timeout from infinite
  /// animations (loading spinner, etc).
  Future<void> pumpForGolden(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(_goldenSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(child);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Widget buildFullProviderHarness({
    required Widget child,
    bool dark = false,
  }) {
    return MaterialApp(
      theme: dark ? darkTheme : lightTheme,
      darkTheme: darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<ImageViewerBloc>.value(value: imageViewerBloc),
            BlocProvider<TtsCubit>.value(value: ttsCubit),
            BlocProvider<FavouritesCubit>.value(value: favouritesCubit),
            BlocProvider<CollectedColorsCubit>.value(value: collectedColorsCubit),
          ],
          child: child,
        ),
      ),
    );
  }

  Widget buildControlBarHarness({
    required ThemeData theme,
    required Widget child,
  }) {
    return MaterialApp(
      theme: theme,
      darkTheme: darkTheme,
      themeMode: theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<ImageViewerBloc>.value(value: imageViewerBloc),
            BlocProvider<TtsCubit>.value(value: ttsCubit),
            BlocProvider<FavouritesCubit>.value(value: favouritesCubit),
          ],
          child: SizedBox(
            width: _goldenSize.width,
            height: _goldenSize.height,
            child: Stack(
              fit: StackFit.expand,
              children: [const SizedBox.expand(), child],
            ),
          ),
        ),
      ),
    );
  }

  group('Golden tests', () {
    testWidgets('control bar collapsed', (tester) async {
      final image = testImage('uid1', 'sig1');
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [image],
        fetchedImages: [],
        selectedImage: image,
        loadingType: ViewerLoadingType.none,
      ));

      await pumpForGolden(
        tester,
        buildControlBarHarness(
          theme: lightTheme,
          child: ControlBar(
            onAnotherTap: () {},
            mode: MainButtonMode.audio,
            onPlayTapped: (_) {},
            backgroundColor: null,
            carouselExpanded: false,
          ),
        ),
      );

      await expectLater(
        find.byType(ControlBar),
        matchesGoldenFile('golden/control_bar_collapsed.png'),
      );
    });

    testWidgets('control bar expanded', (tester) async {
      final image = testImage('uid1', 'sig1');
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [image],
        fetchedImages: [],
        selectedImage: image,
        loadingType: ViewerLoadingType.none,
      ));

      await pumpForGolden(
        tester,
        buildControlBarHarness(
          theme: lightTheme,
          child: ControlBar(
            onAnotherTap: () {},
            mode: MainButtonMode.audio,
            onPlayTapped: (_) {},
            backgroundColor: null,
            carouselExpanded: true,
          ),
        ),
      );

      await expectLater(
        find.byType(ControlBar),
        matchesGoldenFile('golden/control_bar_expanded.png'),
      );
    });

    testWidgets('control bar light mode', (tester) async {
      final image = testImage('uid1', 'sig1');
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [image],
        fetchedImages: [],
        selectedImage: image,
        loadingType: ViewerLoadingType.none,
      ));

      await pumpForGolden(
        tester,
        buildControlBarHarness(
          theme: lightTheme,
          child: ControlBar(
            onAnotherTap: () {},
            mode: MainButtonMode.another,
            onPlayTapped: (_) {},
            backgroundColor: null,
            carouselExpanded: false,
          ),
        ),
      );

      await expectLater(
        find.byType(ControlBar),
        matchesGoldenFile('golden/control_bar_light.png'),
      );
    });

    testWidgets('control bar dark mode', (tester) async {
      final image = testImage('uid1', 'sig1');
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [image],
        fetchedImages: [],
        selectedImage: image,
        loadingType: ViewerLoadingType.none,
      ));

      await pumpForGolden(
        tester,
        buildControlBarHarness(
          theme: darkTheme,
          child: ControlBar(
            onAnotherTap: () {},
            mode: MainButtonMode.another,
            onPlayTapped: (_) {},
            backgroundColor: null,
            carouselExpanded: false,
          ),
        ),
      );

      await expectLater(
        find.byType(ControlBar),
        matchesGoldenFile('golden/control_bar_dark.png'),
      );
    });

    testWidgets('loading indicator state', (tester) async {
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [],
        fetchedImages: [],
        selectedImage: null,
        loadingType: ViewerLoadingType.manual,
      ));

      await pumpForGolden(
        tester,
        MaterialApp(
          theme: lightTheme,
          home: BlocProvider<ImageViewerBloc>.value(
            value: imageViewerBloc,
            child: Scaffold(
              body: BackgroundLoadingIndicator(
                visibleWhen: (state) => state.visibleImages.isEmpty,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BackgroundLoadingIndicator),
        matchesGoldenFile('golden/loading_indicator.png'),
      );
    });

    testWidgets('intro state thumbnail placeholder', (tester) async {
      await pumpForGolden(
        tester,
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: Assets.video.thumbnail.designImage(
                width: 300,
                height: 400,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/intro_state.png'),
      );
    });

    testWidgets('expanded card with long title and description', (tester) async {
      final longTitle =
          'This is an extraordinarily long title that will wrap across multiple '
          'lines to test ellipsis and text overflow behaviour in the expanded view';
      final longDesc =
          'A very lengthy description of the scene: golden sunlight filters '
          'through ancient trees, casting dappled shadows on the forest floor '
          'where wildflowers bloom in profusion. The air is still and warm.';
      final image = ImageModel(
        uid: 'uid1',
        title: longTitle,
        description: longDesc,
        isFavourite: false,
        url: 'https://example.com/1',
        colorPalette: const [Color(0xFF6B4E9D), Color(0xFF4A47A3)],
        localPath: '',
        pixelSignature: 'sig1',
      );

      await pumpForGolden(
        tester,
        buildFullProviderHarness(
          child: ImageViewerBody(
            image: image,
            currentWord: null,
            visible: true,
            onColorsExpanded: (_) {},
          ),
        ),
      );

      await expectLater(
        find.byType(ImageViewerBody),
        matchesGoldenFile('golden/expanded_card_long_text.png'),
      );
    });

    testWidgets('error dialog state', (tester) async {
      await pumpForGolden(
        tester,
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: _ErrorDialogContent(
                    message: ViewerErrorType.noMoreImages.message,
                  ),
                );
              },
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(const Key('error_dialog')),
        matchesGoldenFile('golden/error_dialog.png'),
      );
    });

    testWidgets(
      'carousel collapsed state',
      (tester) async {
        final img1 = testImage('uid1', 'sig1');
        final img2 = testImage('uid2', 'sig2');
        final img3 = testImage('uid3', 'sig3');
        imageViewerBloc.emit(ImageViewerState(
          visibleImages: [img1, img2, img3],
          fetchedImages: [],
          selectedImage: img1,
          loadingType: ViewerLoadingType.none,
        ));

        await pumpForGolden(
          tester,
          buildFullProviderHarness(
            child: ImageViewerScreen(
              onThemeToggle: () {},
            ),
          ),
        );

        await expectLater(
          find.byType(ImageViewerScreen),
          matchesGoldenFile('golden/carousel_collapsed.png'),
        );
      },
    );

    testWidgets(
      'animated background with carousel colors',
      (tester) async {
        final colorsNotifier = ValueNotifier<List<Color>>([
          const Color(0xFF6B4E9D),
          const Color(0xFF4A47A3),
          const Color(0xFF1E88E5),
          const Color(0xFF2E7D32),
          const Color(0xFFD4AF37),
        ]);

        addTearDown(() => colorsNotifier.dispose());

        await pumpForGolden(
          tester,
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: AnimatedBackground(
                colorsListenable: colorsNotifier,
              ),
            ),
          ),
        );

        await expectLater(
          find.byType(AnimatedBackground),
          matchesGoldenFile('golden/animated_background_colors.png'),
        );
      },
    );
  });
}

/// Renders the same structure as [showCustomDialog] for golden testing.
class _ErrorDialogContent extends StatelessWidget {
  const _ErrorDialogContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    // Inverted: light mode → dark popup; dark mode → light popup
    final fillColor = isLight
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.5);
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.25);
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Center(
      key: const Key('error_dialog'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: DefaultTextStyle(
              style: CupertinoTheme.of(context)
                  .textTheme
                  .textStyle
                  .copyWith(color: textColor),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(message, textAlign: TextAlign.center),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    child: Text('OK', style: TextStyle(color: textColor)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
