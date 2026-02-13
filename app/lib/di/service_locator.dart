import 'package:aurora_test/env/env.dart';
import 'package:aurora_test/theme/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:share_service/share_service.dart';
import 'package:tts_service/tts_service.dart';

final GetIt _sl = GetIt.instance;

GetIt get serviceLocator => _sl;

/// Initializes all dependencies. Call before [runApp].
Future<void> configureDependencies() async {
  // Image analysis: switch pipelineType between gemini and chatGpt
  registerImageAnalysisModule(
    _sl,
    pipelineType: ImageAnalysisPipelineType.chatGpt, // or .gemini
    openaiApiKey: Env.openaiApiKey,
  );
  // Initialize pipeline (OpenAI client etc) before first use
  await _sl.get<AbstractImageAnalysisPipeline>().initialize();

  // TTS – key from app/.env
  _sl.registerLazySingleton<AbstractTtsService>(
    () => TtsAudioGenerationService(apiKey: Env.elevenLabsApiKey),
  ); // apiKey is required

  // Share
  _sl.registerLazySingleton<AbstractShareService>(
    () => ShareServiceImpl(),
  );

  // Image viewer: datasource, repository, bloc (factory)
  _sl.registerLazySingleton<ImageRemoteDatasource>(
    () => ImageRemoteDatasourceImpl(),
  );

  _sl.registerLazySingleton<ImageRepository>(
    () => ImageRepositoryImpl(
      remoteDatasource: _sl.get<ImageRemoteDatasource>(),
      imageAnalysisService: _sl.get<ImageAnalysisService>(),
    ),
  );

  _sl.registerFactory<ImageViewerBloc>(
    () => ImageViewerBloc(imageRepository: _sl.get<ImageRepository>()),
  );

  _sl.registerFactory<TtsCubit>(
    () => TtsCubit(ttsService: _sl.get<AbstractTtsService>()),
  );

  _sl.registerFactory<FavouritesCubit>(() => FavouritesCubit());

  _sl.registerLazySingleton<ThemeNotifier>(
    () => ThemeNotifier(initialMode: ThemeMode.dark),
  );
}
