import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_analysis_service/src/domain/models/image_caption_result.dart';
import 'package:image_analysis_service/src/domain/pipelines/abstract_image_analysis_pipeline.dart';
import 'package:mime/mime.dart';
import 'package:openai_dart/openai_dart.dart';

/// Top-level functions for [compute] (must be top-level or static).
String _encodeBase64Isolate(Uint8List bytes) => base64Encode(bytes);

Map<String, dynamic> _decodeJsonIsolate(String content) =>
    jsonDecode(content) as Map<String, dynamic>;

/// ChatGPT-based image analysis pipeline.
/// Implement using OpenAI's vision API (e.g. gpt-4o, gpt-4-vision).
class ChatGptImageAnalysisPipeline implements AbstractImageAnalysisPipeline {
  ChatGptImageAnalysisPipeline({this.apiKey, this.model = 'gpt-4o'});

  final String? apiKey;
  final String model;
  OpenAIClient? _client;

  @override
  Future<void> initialize() async {
    final key = apiKey?.trim();
    if (key != null && key.isNotEmpty) {
      _client = OpenAIClient(apiKey: key);
    }
  }

  static final String _prompt = '''
  You are to describe the image attached and return a JSON object accurately telling what this image represents in terms of a high-networth excursion. 
  This is for ultra rich, so explain as if it's for them. Max 100 words.
  The JSON schema is as follows : {'title': your title, 'description': your description}. No markdown, striclty JSON output''';

  @override
  Future<ImageCaptionResult> analyzeImage({
    required String imagePath,
    required Uint8List imageBytes,
  }) async {
    if (_client == null) await initialize();
    if (_client == null) {
      debugPrint(
        '[ChatGptImageAnalysisPipeline] Not initialized. Pass apiKey in constructor.',
      );
      return const ImageCaptionResult(
        title: 'Error',
        description: 'API key not configured',
      );
    }
    try {
      final mimeType =
          lookupMimeType(imagePath, headerBytes: imageBytes) ?? 'image/jpeg';

      final base64String = await compute(_encodeBase64Isolate, imageBytes);
      final String imageURL = 'data:$mimeType;base64,$base64String';

      final response = await _client?.createChatCompletion(
        request: CreateChatCompletionRequest(
          modalities: [ChatCompletionModality.text],

          model: ChatCompletionModel.modelId(
            'gpt-4.1-mini',
          ), // or other vision-capable model
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                ChatCompletionMessageContentPart.image(
                  imageUrl: ChatCompletionMessageImageUrl(url: imageURL),
                ),
                ChatCompletionMessageContentPart.text(text: _prompt),
              ]),
            ),
          ],
        ),
      );

      final content = response?.choices.first.message.content;

      if (content == null || content.isEmpty) {
        throw Exception('No content in OpenAI response.');
      }

      final map = await compute(_decodeJsonIsolate, content);
      return ImageCaptionResult(
        title: map['title'] as String? ?? 'No title',
        description: map['description'] as String? ?? 'No description',
      );
    } catch (e, stack) {
      debugPrint('[ChatGptImageAnalysisPipeline] Error: $e\n$stack');
      return const ImageCaptionResult(
        title: 'Error',
        description: 'Could not generate description',
      );
    }
  }
}
