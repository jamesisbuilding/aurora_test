import 'package:get_it/get_it.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/bloc/image_viewer_bloc.dart';
import 'package:image_viewer/src/cubit/cubit.dart';
import 'package:image_viewer/src/data/datasources/image_remote_datasource.dart';
import 'package:image_viewer/src/data/repositories/image_repository_impl.dart';
import 'package:image_viewer/src/domain/repositories/image_repository.dart';
import 'package:tts_service/tts_service.dart';

/// Registers image viewer feature dependencies with [GetIt].
/// Requires [ImageAnalysisService] and [AbstractTtsService] to be registered first.
void registerImageViewerModule(GetIt getIt) {
  getIt.registerLazySingleton<ImageRemoteDatasource>(
    () => ImageRemoteDatasourceImpl(),
  );

  getIt.registerLazySingleton<ImageRepository>(
    () => ImageRepositoryImpl(
      remoteDatasource: getIt<ImageRemoteDatasource>(),
      imageAnalysisService: getIt<ImageAnalysisService>(),
    ),
  );

  getIt.registerFactory<ImageViewerBloc>(
    () => ImageViewerBloc(imageRepository: getIt<ImageRepository>()),
  );

  getIt.registerFactory<TtsCubit>(
    () => TtsCubit(ttsService: getIt<AbstractTtsService>()),
  );

  getIt.registerFactory<FavouritesCubit>(() => FavouritesCubit());
  getIt.registerFactory<CollectedColorsCubit>(() => CollectedColorsCubit());
}
