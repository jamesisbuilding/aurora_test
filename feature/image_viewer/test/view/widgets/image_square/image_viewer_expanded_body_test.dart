import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:image_viewer/src/cubit/cubit.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer.dart'
    as iv;
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_body.dart';
import 'package:image_viewer/src/view/widgets/text/animated_text_fill.dart';

import '../../../cubit/fakes/fake_tts_service.dart';
import '../../../data/fakes/fake_image_analysis_service.dart';

void main() {
  late TtsCubit ttsCubit;
  late FakeTtsService fakeTtsService;
  late CollectedColorsCubit collectedColorsCubit;
  late FavouritesCubit favouritesCubit;

  setUp(() {
    fakeTtsService = FakeTtsService();
    ttsCubit = TtsCubit(ttsService: fakeTtsService);
    collectedColorsCubit = CollectedColorsCubit();
    favouritesCubit = FavouritesCubit();
  });

  tearDown(() {
    ttsCubit.close();
    collectedColorsCubit.close();
    favouritesCubit.close();
    fakeTtsService.dispose();
  });

  ImageModel imageWithText(String uid, String title, String description) =>
      ImageModel(
        uid: uid,
        title: title,
        description: description,
        isFavourite: false,
        url: 'https://example.com/$uid',
        colorPalette: const [Color(0xFF000000)],
        localPath: '',
        pixelSignature: 'sig_$uid',
      );

  Widget buildTestHarness({required Widget child}) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<TtsCubit>.value(value: ttsCubit),
          BlocProvider<CollectedColorsCubit>.value(value: collectedColorsCubit),
          BlocProvider<FavouritesCubit>.value(value: favouritesCubit),
        ],
        child: Scaffold(body: child),
      ),
    );
  }

  group('ImageViewer expanded body', () {
    testWidgets('body only appears when expanded', (tester) async {
      final image = testImage('uid1', 'sig1');
      await tester.pumpWidget(
        buildTestHarness(
          child: iv.ImageViewer(
            image: image,
            selected: true,
            disabled: false,
            expanded: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ImageViewerBody), findsNothing);

      await tester.pumpWidget(
        buildTestHarness(
          child: iv.ImageViewer(
            image: image,
            selected: true,
            disabled: false,
            expanded: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ImageViewerBody), findsOneWidget);
    });

    testWidgets('when currentWord is injected, one word span gets highlight '
        'style', (tester) async {
      final image =
          imageWithText('uid1', 'First Second Third', 'Alpha Beta');

      await tester.pumpWidget(
        buildTestHarness(
          child: ImageViewerBody(
            image: image,
            currentWord: (
              word: 'Second',
              isTitle: true,
              wordIndex: 1,
              wordDurationMs: 220,
            ),
            visible: true,
            onColorsExpanded: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final animatedWords =
          tester.widgetList<AnimatedSubtitleWord>(find.byType(AnimatedSubtitleWord)).toList();
      expect(animatedWords.map((w) => w.text), containsAll(['First', 'Second', 'Third']));
      final highlightedWords = animatedWords.where((w) => w.isActive).toList();
      expect(highlightedWords.length, 1);
      expect(highlightedWords.single.text, 'Second');
      expect(highlightedWords.single.duration, const Duration(milliseconds: 220));
    });

    testWidgets('title vs description index mapping displays expected '
        'highlighted token', (tester) async {
      final image =
          imageWithText('uid1', 'Title A B', 'Desc X Y Z');
      await tester.pumpWidget(
        buildTestHarness(
          child: ImageViewerBody(
            image: image,
            currentWord: (
              word: 'A',
              isTitle: true,
              wordIndex: 1,
              wordDurationMs: 220,
            ),
            visible: true,
            onColorsExpanded: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      var animatedWords =
          tester.widgetList<AnimatedSubtitleWord>(find.byType(AnimatedSubtitleWord)).toList();
      var highlighted = animatedWords.where((w) => w.isActive);
      expect(highlighted.length, 1);
      expect(highlighted.single.text, 'A');

      await tester.pumpWidget(
        buildTestHarness(
          child: ImageViewerBody(
            image: image,
            currentWord: (
              word: 'X',
              isTitle: false,
              wordIndex: 1,
              wordDurationMs: 220,
            ),
            visible: true,
            onColorsExpanded: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final descWords =
          tester.widgetList<AnimatedSubtitleWord>(find.byType(AnimatedSubtitleWord)).toList();
      final descHighlighted = descWords.where((w) => w.isActive);
      expect(descHighlighted.length, 1);
      expect(descHighlighted.single.text, 'X');
    });
  });
}
