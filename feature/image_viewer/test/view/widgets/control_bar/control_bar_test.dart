import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:image_viewer/src/view/widgets/control_bar/control_bar.dart';
import 'package:image_viewer/src/view/widgets/loading/background_loading_indicator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

import '../../../bloc/image_viewer_bloc_test_utils.dart';
import '../../../cubit/fakes/fake_tts_service.dart';
import '../../../data/fakes/fake_image_analysis_service.dart';

void main() {
  late ImageViewerBloc imageViewerBloc;
  late TtsCubit ttsCubit;
  late FakeTtsService fakeTtsService;
  late MockImageRepository mockRepo;
  late FavouritesCubit favouritesCubit;
  ScrollDirectionCubit? scrollDirectionCubit;

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
    scrollDirectionCubit = ScrollDirectionCubit();
  });

  tearDown(() {
    imageViewerBloc.close();
    ttsCubit.close();
    favouritesCubit.close();
    scrollDirectionCubit?.close();
    fakeTtsService.dispose();
  });

  Widget buildTestHarness({
    required Widget child,
  }) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<ImageViewerBloc>.value(value: imageViewerBloc),
            BlocProvider<TtsCubit>.value(value: ttsCubit),
            BlocProvider<FavouritesCubit>.value(value: favouritesCubit),
            BlocProvider<ScrollDirectionCubit>.value(
                value: scrollDirectionCubit!),
          ],
          child: Stack(
            fit: StackFit.expand,
            children: [
              const SizedBox.expand(),
              child,
            ],
          ),
        ),
      ),
    );
  }

  double _indicatorOpacity(WidgetTester tester) {
    final match = find.byType(BackgroundLoadingIndicator);
    if (!tester.any(match)) return 0.0;
    final opacityWidget = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: match.first,
        matching: find.byType(AnimatedOpacity),
      ).first,
    );
    return opacityWidget.opacity;
  }

  group('ControlBar background loading indicator', () {
    testWidgets('visible when background loading and has images, carousel not expanded',
        (tester) async {
      final image = testImage('uid1', 'sig1');
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [image],
        fetchedImages: [],
        selectedImage: image,
        loadingType: ViewerLoadingType.background,
      ));

      await tester.pumpWidget(
        buildTestHarness(
          child: ControlBar(
            onAnotherTap: noop,
            mode: MainButtonMode.another,
            onPlayTapped: (_) {},
            backgroundColor: null,
            carouselExpanded: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BackgroundLoadingIndicator), findsOneWidget);
      final opacity = _indicatorOpacity(tester);
      expect(opacity, 1.0);
    });

    testWidgets('not visible when manual loading', (tester) async {
      final image = testImage('uid1', 'sig1');
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [image],
        fetchedImages: [],
        selectedImage: image,
        loadingType: ViewerLoadingType.manual,
      ));

      await tester.pumpWidget(
        buildTestHarness(
          child: ControlBar(
            onAnotherTap: noop,
            mode: MainButtonMode.audio,
            onPlayTapped: (_) {},
            backgroundColor: null,
            carouselExpanded: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final opacity = _indicatorOpacity(tester);
      expect(opacity, 0.0);
    });

    testWidgets('not visible when no visible images', (tester) async {
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [],
        fetchedImages: [],
        selectedImage: null,
        loadingType: ViewerLoadingType.background,
      ));

      await tester.pumpWidget(
        buildTestHarness(
          child: ControlBar(
            onAnotherTap: noop,
            mode: MainButtonMode.another,
            onPlayTapped: (_) {},
            backgroundColor: null,
            carouselExpanded: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final opacity = _indicatorOpacity(tester);
      expect(opacity, 0.0);
    });

    testWidgets('indicator not in tree when carousel expanded', (tester) async {
      final image = testImage('uid1', 'sig1');
      imageViewerBloc.emit(ImageViewerState(
        visibleImages: [image],
        fetchedImages: [],
        selectedImage: image,
        loadingType: ViewerLoadingType.background,
      ));

      await tester.pumpWidget(
        buildTestHarness(
          child: ControlBar(
            onAnotherTap: noop,
            mode: MainButtonMode.audio,
            onPlayTapped: (_) {},
            backgroundColor: null,
            carouselExpanded: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BackgroundLoadingIndicator), findsNothing);
    });
  });
}
