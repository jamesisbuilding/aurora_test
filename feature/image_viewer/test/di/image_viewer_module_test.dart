import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/bloc/image_viewer_bloc.dart';
import 'package:image_viewer/src/cubit/cubit.dart';
import 'package:image_viewer/src/data/datasources/image_remote_datasource.dart';
import 'package:image_viewer/src/di/image_viewer_module.dart';
import 'package:image_viewer/src/domain/repositories/image_repository.dart';
import 'package:tts_service/tts_service.dart';

import '../cubit/fakes/fake_tts_service.dart';
import '../data/fakes/fake_image_analysis_service.dart';

void main() {
  late GetIt getIt;

  setUp(() {
    getIt = GetIt.asNewInstance();
    getIt.registerSingleton<ImageAnalysisService>(FakeImageAnalysisService());
    getIt.registerSingleton<AbstractTtsService>(FakeTtsService());
  });

  tearDown(() async => await getIt.reset());

  group('registerImageViewerModule', () {
    test('registers and resolves ImageRemoteDatasource', () {
      registerImageViewerModule(getIt);

      final ds = getIt<ImageRemoteDatasource>();
      expect(ds, isNotNull);
    });

    test('registers and resolves ImageRepository', () {
      registerImageViewerModule(getIt);

      final repo = getIt<ImageRepository>();
      expect(repo, isNotNull);
    });

    test('registers and resolves ImageViewerBloc', () {
      registerImageViewerModule(getIt);

      final bloc = getIt<ImageViewerBloc>();
      expect(bloc, isNotNull);
      bloc.close();
    });

    test('registers and resolves TtsCubit', () {
      registerImageViewerModule(getIt);

      final cubit = getIt<TtsCubit>();
      expect(cubit, isNotNull);
      cubit.close();
    });

    test('registers and resolves FavouritesCubit', () {
      registerImageViewerModule(getIt);

      final cubit = getIt<FavouritesCubit>();
      expect(cubit, isNotNull);
      cubit.close();
    });

    test('registers and resolves CollectedColorsCubit', () {
      registerImageViewerModule(getIt);

      final cubit = getIt<CollectedColorsCubit>();
      expect(cubit, isNotNull);
      cubit.close();
    });

    test('registers and resolves ScrollDirectionCubit', () {
      registerImageViewerModule(getIt);

      final cubit = getIt<ScrollDirectionCubit>();
      expect(cubit, isNotNull);
      cubit.close();
    });
  });
}
