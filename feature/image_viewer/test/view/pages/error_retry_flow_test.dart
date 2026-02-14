import 'dart:async' show TimeoutException;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:mocktail/mocktail.dart';

import '../../bloc/image_viewer_bloc_test_utils.dart';
import '../../cubit/fakes/fake_tts_service.dart';

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

void main() {
  late MockImageRepository mockRepository;

  setUp(() {
    mockRepository = MockImageRepository();
  });

  testWidgets(
      'error with no visible images: dialog shown, on dismiss retries fetch',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(() => tester.view.resetPhysicalSize());

    var callCount = 0;
    when(() => mockRepository.runImageRetrieval(
          count: any(named: 'count'),
          existingImages: any(named: 'existingImages'),
        )).thenAnswer((_) {
      callCount++;
      if (callCount == 1) {
        return Stream.error(TimeoutException('test'));
      }
      return Stream.value(_image('uid1', 'sig1'));
    });

    late ImageViewerBloc bloc;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) {
                bloc = ImageViewerBloc(imageRepository: mockRepository);
                bloc.add(const ImageViewerFetchRequested(
                  count: 1,
                  loadingType: ViewerLoadingType.background,
                ));
                return bloc;
              },
            ),
            BlocProvider(create: (_) => TtsCubit(ttsService: FakeTtsService())),
            BlocProvider(create: (_) => FavouritesCubit()),
            BlocProvider(create: (_) => CollectedColorsCubit()),
          ],
          child: ImageViewerScreen(onThemeToggle: () {}),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(bloc.state.errorType, isNot(ViewerErrorType.none));
    expect(bloc.state.visibleImages, isEmpty);
    expect(callCount, 1);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('timed out'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(bloc.state.errorType, ViewerErrorType.none);
    expect(bloc.state.visibleImages, isNotEmpty);
    expect(bloc.state.visibleImages.first.uid, 'uid1');
    expect(callCount, 2);

    await tester.pump(const Duration(milliseconds: 300));
  });
}
