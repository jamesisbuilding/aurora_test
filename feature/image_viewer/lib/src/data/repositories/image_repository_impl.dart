import 'package:flutter/foundation.dart';
import 'package:image_analysis_service/image_analysis_service.dart';

import 'package:image_viewer/src/data/datasources/image_remote_datasource.dart';
import 'package:image_viewer/src/domain/exceptions/image_viewer_exceptions.dart';
import 'package:image_viewer/src/domain/repositories/image_repository.dart';

const _maxRetriesPerSlot = 3;
const _initialBackoffMs = 500;
const _maxSequentialDuplicates = 3;

class ImageRepositoryImpl implements ImageRepository {
  ImageRepositoryImpl({
    required ImageRemoteDatasource remoteDatasource,
    required ImageAnalysisService imageAnalysisService,
  }) : _remoteDatasource = remoteDatasource,
       _imageAnalysisService = imageAnalysisService;

  final ImageRemoteDatasource _remoteDatasource;
  final ImageAnalysisService _imageAnalysisService;

  @override
  Stream<ImageModel> runImageRetrieval({
    int count = 1,
    List<ImageModel> existingImages = const [],
  }) async* {
    var collected = List<ImageModel>.from(existingImages);
    var needed = count;
    var backoffMs = _initialBackoffMs;

    int _duplicatesFound = 0;
    for (var round = 0; round <= _maxRetriesPerSlot && needed > 0; round++) {
      final urls = await Future.wait<String>(
        List.generate(needed, (_) => _remoteDatasource.getRandomImageUrl()),
      );

      var failures = 0;
      for (final url in urls) {
        if (collected.map((i) => i.url).contains(url)) {
          debugPrint('[ImageRepo] IMAGE DUPLICATE ABORTING ANALYSIS');
          _duplicatesFound += 1;

        
          if (_duplicatesFound >= _maxSequentialDuplicates) {
            throw NoMoreImagesException('Too many sequential duplicates');
          }

          failures++;
          break;
        }

        final result = await _imageAnalysisService.runImageAnalysisService(
          imageURL: url,
          existingImages: collected,
        );
        result.when(
          success: (model) => collected = [...collected, model],
          failure: (_) => failures++,
        );
        if (result case Success(:final value)) yield value;
      }
      needed = failures;

      if (needed == 0) break;
      if (round < _maxRetriesPerSlot) {
        await Future.delayed(Duration(milliseconds: backoffMs));
        backoffMs *= 2;
      }
    }

    if (collected.isEmpty) {
      throw Exception('All image analyses failed after retries');
    }
  }
}
