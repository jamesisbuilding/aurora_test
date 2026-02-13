import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:image_analysis_service/src/domain/models/image_caption_result.dart';
import 'package:image_analysis_service/src/domain/pipelines/abstract_image_analysis_pipeline.dart';
import 'package:mime/mime.dart';

/// Gemini-based image analysis pipeline using Firebase AI.
class GeminiImageAnalysisPipeline implements AbstractImageAnalysisPipeline {
  GeminiImageAnalysisPipeline();

  static final Schema _schema = Schema(
    SchemaType.object,
    properties: {
      'title': Schema(SchemaType.string),
      'description': Schema(SchemaType.string),
    },
  );

  static final String _prompt = '''
  You are to describe the image attached and return a JSON object accurately representing the image. 
  The JSON schema is as follows : ${jsonEncode(_schema.toJson())}''';

  @override
  Future<void> initialize() async {}

  @override
  Future<ImageCaptionResult> analyzeImage({
    required String imagePath,
    required Uint8List imageBytes,
  }) async {
    final mimeType =
        lookupMimeType(imagePath, headerBytes: imageBytes) ?? 'image/jpeg';

    final List<Part> contentParts = [
      TextPart(_prompt),
      InlineDataPart(mimeType, imageBytes),
    ];

    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-pro-image-preview',
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text],
        responseMimeType: 'application/json',
        responseSchema: _schema,
      ),
    );

    try {
      final response = await model.generateContent([
        Content.multi(contentParts),
      ]);
      final map = jsonDecode(response.text!) as Map<String, dynamic>;
      return ImageCaptionResult(
        title: map['title'] as String? ?? 'No title',
        description: map['description'] as String? ?? 'No Caption',
      );
    } catch (e, stack) {
      debugPrint('[GeminiImageAnalysisPipeline] Error: $e\n$stack');
      return const ImageCaptionResult(
        title: 'Error',
        description: 'Could not generate story',
      );
    }
  }
}
