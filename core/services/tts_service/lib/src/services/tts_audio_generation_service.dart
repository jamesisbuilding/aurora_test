import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tts_service/src/abstract_tts_service.dart';
import 'package:tts_service/src/env/env.dart';

/// Fallback voice if v2/voices returns empty.
const _fallbackVoiceId = '21m00Tcm4TlvDq8ikWAM';

/// TTS model (matches curl: eleven_multilingual_v2).
const _defaultModelId = 'eleven_turbo_v2_5';

class TtsAudioGenerationService implements AbstractTtsService {
  TtsAudioGenerationService._internal();

  static final TtsAudioGenerationService _instance =
      TtsAudioGenerationService._internal();

  factory TtsAudioGenerationService() => _instance;

  Dio? _dio;
  final player = AudioPlayer();
  StreamSubscription<PlayerState>? _completionSubscription;
  bool _isSpeaking = false;
  bool _initialized = false;
  String _voiceId = _fallbackVoiceId;

  bool get isSpeaking => _isSpeaking;
  String? key;

  /// Loads API key, sets up Dio instance if needed.
  Future<void> initialize() async {
    key = Env.elevenLabsApiKey.trim();

    // Initialize Dio if not already instantiated
    _dio ??= Dio(
      BaseOptions(
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': key!,
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.bytes,
      ),
    );

    _initialized = true;
  }

  Future<void> playTextToSpeech(
    String text, {
    void Function()? onPlaybackComplete,
  }) async {
    if (!_initialized) await initialize();
    if (_isSpeaking) await stop();

    _isSpeaking = true;
    try {
      final url = 'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId';
      final data = {
        'text': text,
        'model_id': _defaultModelId,
        'voice_settings': {'stability': 0.15, 'similarity_boost': 0.75},
      };

      final response = await _dio!.post(
        url,
        data: json.encode(data),
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            // These headers override or complement the defaults in BaseOptions
            'Accept': 'audio/mpeg',
            'xi-api-key': key!,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        if (bytes.isEmpty) throw Exception('Empty audio response');
        await _completionSubscription?.cancel();
        _completionSubscription = player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _completionSubscription?.cancel();
            _completionSubscription = null;
            onPlaybackComplete?.call();
          }
        });
        await player.setAudioSource(MyCustomSource(bytes));
        // Don't await play() - it completes when playback *ends*, not when it starts
        player.play();
      } else {
        throw Exception(
          'Failed to load audio: ${response.statusCode} ${response.data}',
        );
      }
    } catch (e) {
      await _completionSubscription?.cancel();
      _completionSubscription = null;
      debugPrint('[TTS] Error: $e');
      rethrow;
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    await _completionSubscription?.cancel();
    _completionSubscription = null;
    await player.stop();
    _isSpeaking = false;
  }
}

class MyCustomSource extends StreamAudioSource {
  final List<int> bytes;
  MyCustomSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    end = end.clamp(0, bytes.length);
    start = start.clamp(0, end);
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
