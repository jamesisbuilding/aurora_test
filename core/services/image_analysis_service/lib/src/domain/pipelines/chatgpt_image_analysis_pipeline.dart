import 'dart:convert';

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
  You are to create an artistic interpretation of the image provided return strings that give a vibe of luxury and artistry without sounding cliche. 
  Each image is an experience or event a rich person can buy. 

  You are to return: 

  title (max 3 words) - an abstract yet relevant title of what the image represents.
  description (max 40 words) - an small artistic description
  founder name (max 3 words) - The name of the person who founded this event, this person's name is unisex. 
  founder description (max 30-40 words) - a description of the founder
  description 2 (max 60 words) - a more in depth description of the event, as if the user has just seen 4 more images of the event 
  hype building tag line #1 (max 2 words including spaces) - the first in a list of hype up tag lines seen by the user about the event
  hype building tag line #2 (max 2 words including spaces) - the second in a list of hype up tag lines seen by the user about the event
  hype building tag line #3 (max 2 words including spaces) - the third in a list of hype up tag lines seen by the user about the event
  hype building tag line #4 (max 2 words including spaces) - the fourth in a list of hype up tag lines seen by the user about the event
  hype building tag line #5 (max 2 words including spaces) - the firth in a list of hype up tag lines seen by the user about the event

Return your answer in the following JSON format, with the keys exactly as shown:
{
  "title": "",
  "description": "",
  "founder name": "",
  "founder description": "",
  "description 2": "",
  "hype building tag line #1": "",
  "hype building tag line #2": "",
  "hype building tag line #3": "",
  "hype building tag line #4": "",
  "hype building tag line #5": ""
}
''';
  
  // '''
  // You are to describe the image attached and return a JSON object accurately telling what this image represents in terms of a high-networth excursion. 
  // This is for ultra rich, so explain as if it's for them. Max 100 words.
  // The JSON schema is as follows : {'title': your title, 'description': your description}. No markdown, striclty JSON output''';

  @override
  Future<ImageCaptionResult> analyzeImage({
    required String imagePath,
    required Uint8List imageBytes,
  }) async {
    if (_client == null) await initialize();
    if (_client == null) {
      if (kDebugMode) {
        debugPrint('[ChatGptImageAnalysisPipeline] Not initialized. Pass apiKey in constructor.');
      }
      return const ImageCaptionResult(
        title: 'Error',
        description: '',
        founderName: '',
        founderDescription: '',
        description2: '',
        hypeBuildingTagline1: '',
        hypeBuildingTagline2: '',
        hypeBuildingTagline3: '',
        hypeBuildingTagline4: '',
        hypeBuildingTagline5: '',
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
        founderName: map['founder name'] as String? ?? '',
        founderDescription: map['founder description'] as String? ?? '',
        description2: map['description 2'] as String? ?? '',
        hypeBuildingTagline1: map['hype building tag line #1'] as String? ?? '',
        hypeBuildingTagline2: map['hype building tag line #2'] as String? ?? '',
        hypeBuildingTagline3: map['hype building tag line #3'] as String? ?? '',
        hypeBuildingTagline4: map['hype building tag line #4'] as String? ?? '',
        hypeBuildingTagline5: map['hype building tag line #5'] as String? ?? '',
      );
    } catch (e, stack) {
      if (kDebugMode) debugPrint('[ChatGptImageAnalysisPipeline] Error: $e\n$stack');
      return const ImageCaptionResult(
        title: 'Error',
        description: 'Could not generate description',
        founderName: '',
        founderDescription: '',
        description2: '',
        hypeBuildingTagline1: '',
        hypeBuildingTagline2: '',
        hypeBuildingTagline3: '',
        hypeBuildingTagline4: '',
        hypeBuildingTagline5: '',
      );
    }
  }
}
