import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tts_service/src/abstract_tts_service.dart';
import 'package:tts_service/src/models/tts_current_word.dart';

/// Fallback voice if v2/voices returns empty.
const _fallbackVoiceId = '21m00Tcm4TlvDq8ikWAM';

/// TTS model (matches curl: eleven_multilingual_v2).
const _defaultModelId = 'eleven_turbo_v2_5';

/// Top-level function for [compute] (must be top-level or static).
Uint8List _decodeBase64Isolate(String input) => base64Decode(input);

class TtsAudioGenerationService implements AbstractTtsService {
  TtsAudioGenerationService._internal({required String apiKey})
    : _apiKey = apiKey.trim();

  static TtsAudioGenerationService? _instance;
  final String _apiKey;

  /// Requires [apiKey] from host app (e.g. app/.env).
  factory TtsAudioGenerationService({required String apiKey}) {
    _instance ??= TtsAudioGenerationService._internal(apiKey: apiKey);
    return _instance!;
  }

  Dio? _dio;
  final player = AudioPlayer();
  StreamSubscription<PlayerState>? _completionSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  final _currentWordController = StreamController<TtsCurrentWord>.broadcast();
  bool _isSpeaking = false;
  bool _initialized = false;
  String _voiceId = _fallbackVoiceId;

  bool get isSpeaking => _isSpeaking;
  String? key;

  @override
  Stream<TtsCurrentWord> get currentWordStream => _currentWordController.stream;

  /// Loads API key, sets up Dio instance if needed.
  Future<void> initialize() async {
    key = _apiKey;

    // Initialize Dio if not already instantiated
    _dio ??= Dio(
      BaseOptions(
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': key!,
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    _initialized = true;
  }

  Future<void> playTextToSpeech(
    String title,
    String description, {
    VoidCallback? onPlaybackComplete,
    Future<void>? cancelWhen,
    bool Function()? isCancelled,
  }) async {
    if (!_initialized) await initialize();
    if (_isSpeaking) await stop();

    _isSpeaking = true;
    final text = '$title. $description'.trim();
    if (text.isEmpty) {
      _isSpeaking = false;
      return;
    }
    final cancelToken = CancelToken();
    cancelWhen?.then((_) => cancelToken.cancel());
    try {
      final url =
          'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId/with-timestamps';
      final data = {
        'text': text,
        'model_id': _defaultModelId,
        'voice_settings': {'stability': 0.15, 'similarity_boost': 0.75},
      };

      final response = await _dio!.post(
        url,
        data: json.encode(data),
        options: Options(
          responseType: ResponseType.json,
          headers: {
            // These headers override or complement the defaults in BaseOptions
            'Accept': 'audio/mpeg',
            'xi-api-key': key!,
            'Content-Type': 'application/json',
          },
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {

       
        // Base64 data
        final base64Audio = response.data['audio_base64'];
        if (base64Audio == null) {
          throw Exception('failed-audio-bytes');
        }

        final cleanBase64 = base64Audio.contains(',')
            ? base64Audio.split(',').last.trim()
            : base64Audio.trim();

        // 2. Decode the string into a Uint8List (offloaded to isolate)
        final bytes = await compute<String, Uint8List>(_decodeBase64Isolate, cleanBase64);

        if (bytes.isEmpty) throw Exception('Empty audio response');
        await _completionSubscription?.cancel();
        await _positionSubscription?.cancel();
        _completionSubscription = null;
        _positionSubscription = null;

        final charsRaw = response.data['normalized_alignment']?['characters'];
        final timesRaw = response.data['normalized_alignment']?['character_start_times_seconds'];
        final chars = charsRaw is List ? List<dynamic>.from(charsRaw) : null;
        final charTimes = timesRaw is List ? List<dynamic>.from(timesRaw) : null;

        _completionSubscription = player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _completionSubscription?.cancel();
            _completionSubscription = null;
            _positionSubscription?.cancel();
            _positionSubscription = null;
            onPlaybackComplete?.call();
          }
        });

        if (chars != null && charTimes != null && chars.isNotEmpty) {
          final words = _buildWordsWithIndices(chars, charTimes);
          final titleWordCount = _wordCount(title);
          TtsCurrentWord? lastEmitted;
          _positionSubscription = player.positionStream.listen((position) {
            final posSec = position.inMilliseconds / 1000.0;
            final current =
                _currentWordAtPosition(posSec, words, titleWordCount);
            final prev = lastEmitted;
            if (current != null &&
                (prev == null ||
                    prev.wordIndex != current.wordIndex ||
                    prev.isTitle != current.isTitle ||
                    prev.word != current.word)) {
              lastEmitted = current;
              _currentWordController.add(current);
              debugPrint(
                  '[TTS] ${current.isTitle ? "title" : "desc"}[${current.wordIndex}]: "${current.word}"');
            }
          });
        }

        if (isCancelled?.call() ?? false) return;
        await player.setAudioSource(MyCustomSource(bytes));
        if (isCancelled?.call() ?? false) return;
        player.play();
      } else {
        throw Exception(
          'Failed to load audio: ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e, st) {
      if (e.type == DioExceptionType.cancel) {
        return;
      }
      await _completionSubscription?.cancel();
      await _positionSubscription?.cancel();
      _completionSubscription = null;
      _positionSubscription = null;
      if (kDebugMode) debugPrint('[TTS] Error: $e\n$st');
      rethrow;
    } catch (e, st) {
      await _completionSubscription?.cancel();
      await _positionSubscription?.cancel();
      _completionSubscription = null;
      _positionSubscription = null;
      if (kDebugMode) debugPrint('[TTS] Error: $e\n$st');
      rethrow;
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    await _completionSubscription?.cancel();
    await _positionSubscription?.cancel();
    _completionSubscription = null;
    _positionSubscription = null;
    await player.stop();
    _isSpeaking = false;
  }
}


bool _isSpace(String s) =>
    s.length == 1 && (s == ' ' || s == '\n' || s == '\t' || s == '\r');

/// Precomputes words with index, text, start and end times from chars + charTimes.
List<({int index, String word, double start, double end})> _buildWordsWithIndices(
  List<dynamic> chars,
  List<dynamic> charTimes,
) {
  final result = <({int index, String word, double start, double end})>[];
  if (chars.isEmpty || charTimes.isEmpty) return result;
  final n = chars.length;
  final times = charTimes.map((e) => (e as num).toDouble()).toList();

  var wordIndex = 0;
  var i = 0;
  while (i < n) {
    if (_isSpace(chars[i] as String)) {
      i++;
      continue;
    }
    final start = i;
    final startSec = times[i];
    while (i < n && !_isSpace(chars[i] as String)) i++;
    final end = i - 1;
    final endSec = i < n ? times[i] : (times[end] + 0.1);
    final word =
        chars.sublist(start, end + 1).map((e) => e as String).join().trim();
    if (word.isNotEmpty) {
      result.add((index: wordIndex++, word: word, start: startSec, end: endSec));
    }
  }
  return result;
}

int _wordCount(String text) {
  if (text.trim().isEmpty) return 0;
  return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
}

/// Returns the current word at [positionSec] from precomputed [words].
/// [titleWordCount] splits global index into title vs description.
TtsCurrentWord? _currentWordAtPosition(
  double positionSec,
  List<({int index, String word, double start, double end})> words,
  int titleWordCount,
) {
  for (final w in words) {
    if (positionSec >= w.start && positionSec < w.end) {
      final isTitle = w.index < titleWordCount;
      final wordIndex = isTitle ? w.index : w.index - titleWordCount;
      final durationMs = ((w.end - w.start) * 1000).round().clamp(1, 10000);
      return (
        word: w.word,
        isTitle: isTitle,
        wordIndex: wordIndex,
        wordDurationMs: durationMs,
      );
    }
  }
  return null;
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
