import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_analysis_service/src/domain/models/analysis_result.dart';
import 'package:image_analysis_service/src/domain/models/image_model.dart';
import 'package:image_analysis_service/src/domain/models/image_caption_result.dart';
import 'package:image_analysis_service/src/domain/pipelines/abstract_image_analysis_pipeline.dart';
import 'package:image_analysis_service/src/domain/pipelines/gemini_image_analysis_pipeline.dart';
import 'package:image_analysis_service/src/utils/isolate_palette_extractor.dart';
import 'package:image_analysis_service/src/utils/isolate_tasks.dart';
import 'package:image_analysis_service/src/utils/network_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageAnalysisService {
  ImageAnalysisService({
    AbstractImageAnalysisPipeline? pipeline,
  }) : _pipeline = pipeline ?? GeminiImageAnalysisPipeline();

  final AbstractImageAnalysisPipeline _pipeline;

  Future<Result<ImageModel>> runImageAnalysisService({
    required String imageURL,
    List<ImageModel> existingImages = const [],
  }) async {
    try {
      final imageBytes = await compute(fetchImageBytesInIsolate, imageURL);

      if (imageBytes == null) {
        return Failure('Failed to fetch image from URL');
      }

      final existingHashes = existingImages
          .map((e) => e.pixelSignature)
          .whereType<String>()
          .toList();
      final hashResult = await compute(
        hashAndCheckDuplicate,
        (imageBytes, existingHashes),
      );
      if (hashResult.isDuplicate) {
        return Failure('Duplicate image detected', type: FailureType.duplicate);
      }
      final contentHash = hashResult.hash!;

      final String imageID = generateRandomId();
      // Save image to local storage
      final String localPath = await _saveImageLocally(imageBytes, imageID);

      // Run color analysis in isolate and AI pipeline on main, in parallel
      final results = await Future.wait([
        compute(extractPaletteFromBytes, imageBytes)
            .then((argb) => argb.map((v) => Color(v)).toList()),
        _pipeline.analyzeImage(
          imagePath: localPath,
          imageBytes: imageBytes,
        ),
      ]);

      List<Color> colorPalette = results[0] as List<Color>;
      final caption = results[1] as ImageCaptionResult;

      final model = ImageModel(
        uid: imageID,
        title: caption.title,
        description: caption.description,
        isFavourite: false,
        url: imageURL,
        colorPalette: colorPalette,
        localPath: localPath,
        byteList: imageBytes,
        pixelSignature: contentHash,
        founderName: caption.founderName,
        founderDescription: caption.founderDescription,
        description2: caption.description2,
        hypeBuildingTagline1: caption.hypeBuildingTagline1,
        hypeBuildingTagline2: caption.hypeBuildingTagline2,
        hypeBuildingTagline3: caption.hypeBuildingTagline3,
        hypeBuildingTagline4: caption.hypeBuildingTagline4,
        hypeBuildingTagline5: caption.hypeBuildingTagline5,
      );
      if (model.url.isEmpty) {
        return Failure('Analysis returned empty model');
      }
      return Success(model);
    } catch (e) {
      return Failure('Image analysis failed: $e');
    }
  }

  /// Runs palette extraction in a background isolate to avoid UI jank.
  Future<List<Color>> runColorAnalysis({required Uint8List imageBytes}) async {
    try {
      final argb = await compute(extractPaletteFromBytes, imageBytes);
      return argb.map((v) => Color(v)).toList();
    } catch (e, stack) {
      debugPrint('[runColorAnalysis] Color Analysis Error: $e\n$stack');
      return [Colors.transparent];
    }
  }

  Future<String> _saveImageLocally(Uint8List bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();

    final folderPath = Directory(p.join(tempDir.path, 'viewer_cache'));

    // Ensure the folder exists before writing
    if (!await folderPath.exists()) {
      await folderPath.create(recursive: true);
    }

    final filePath = p.join(folderPath.path, '$fileName.png');
    final file = File(filePath);

    await file.writeAsBytes(bytes);

    return file.path;
  }

  Future<void> wipeViewerCache() async {
    try {
      
      final tempDir = await getTemporaryDirectory();

      final cacheDirectory = Directory(p.join(tempDir.path, 'viewer_cache'));

      if (await cacheDirectory.exists()) {
        
        await cacheDirectory.delete(recursive: true);
      }
    } catch (_) {
      debugPrint('Unable to wipe cache');
    }
  }
}
