import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:tts_service/tts_service.dart';

import 'fakes/fake_tts_service.dart';

void main() {
  late FakeTtsService fakeTtsService;
  late TtsCubit cubit;

  setUp(() {
    fakeTtsService = FakeTtsService();
    cubit = TtsCubit(ttsService: fakeTtsService);
  });

  tearDown(() {
    cubit.close();
    fakeTtsService.dispose();
  });

  group('TtsCubit transitions', () {
    test('play() emits loading -> playing', () async {
      final states = <TtsState>[];
      final sub = cubit.stream.listen(states.add);

      unawaited(cubit.play('Title', 'Description'));

      await Future<void>.delayed(Duration.zero);

      expect(states.length, greaterThanOrEqualTo(1));
      expect(states.first.isLoading, true);

      await Future<void>.delayed(Duration(milliseconds: 50));

      sub.cancel();

      final playingState = states.lastWhere(
        (s) => s.isPlaying,
        orElse: () => states.last,
      );
      expect(playingState.isLoading, false);
      expect(playingState.isPlaying, true);
    });

    test('onPlaybackComplete clears isPlaying/currentWord', () async {
      fakeTtsService.completeImmediately = false;

      final states = <TtsState>[];
      final sub = cubit.stream.listen(states.add);

      unawaited(cubit.play('Title', 'Description'));
      await Future<void>.delayed(Duration(milliseconds: 50));

      fakeTtsService.emitWord((
        word: 'hello',
        isTitle: true,
        wordIndex: 0,
        wordDurationMs: 220,
      ));
      await Future<void>.delayed(Duration.zero);

      fakeTtsService.triggerPlaybackComplete();
      await Future<void>.delayed(Duration.zero);

      sub.cancel();

      final clearedState = states.last;
      expect(clearedState.isPlaying, false);
      expect(clearedState.currentWord, isNull);
    });

    test('stop() always clears state', () async {
      fakeTtsService.completeImmediately = false;

      unawaited(cubit.play('Title', 'Description'));
      await Future<void>.delayed(Duration(milliseconds: 50));

      await cubit.stop();

      expect(cubit.state.isLoading, false);
      expect(cubit.state.isPlaying, false);
      expect(cubit.state.currentWord, isNull);
    });

    test('exception in TTS service resets state and rethrows', () async {
      fakeTtsService.shouldThrow = true;

      await expectLater(
        cubit.play('Title', 'Description'),
        throwsA(isA<Exception>()),
      );

      expect(cubit.state.isLoading, false);
      expect(cubit.state.isPlaying, false);
      expect(cubit.state.currentWord, isNull);
    });

    test('stop() during loading prevents isPlaying from ever being emitted',
        () async {
      fakeTtsService.delayPlayReturn = true;
      fakeTtsService.completeImmediately = false;

      final states = <TtsState>[];
      final sub = cubit.stream.listen(states.add);

      unawaited(cubit.play('Title', 'Description'));
      await Future<void>.delayed(Duration.zero);

      expect(states.last.isLoading, true);
      expect(states.any((s) => s.isPlaying), false);

      await cubit.stop();

      fakeTtsService.completePlayReturn();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      sub.cancel();

      expect(cubit.state.isLoading, false);
      expect(cubit.state.isPlaying, false);
      expect(states.any((s) => s.isPlaying), false);
    });
  });

  group('TTS happy + failure path', () {
    test('start audio from expanded card: playing state confirmed', () async {
      final states = <TtsState>[];
      final sub = cubit.stream.listen(states.add);

      unawaited(cubit.play('Sunset over ocean', 'A golden horizon.'));

      await Future<void>.delayed(Duration.zero);

      expect(states.length, greaterThanOrEqualTo(1));
      expect(states.first.isLoading, true);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      sub.cancel();

      final playingState = states.lastWhere(
        (s) => s.isPlaying,
        orElse: () => states.last,
      );
      expect(playingState.isLoading, false);
      expect(playingState.isPlaying, true);
    });

    test('word stream progression updates currentWord in order', () async {
      fakeTtsService.completeImmediately = false;

      final wordsSeen = <TtsCurrentWord>[];
      cubit.stream.listen((s) {
        if (s.currentWord != null) wordsSeen.add(s.currentWord!);
      });

      unawaited(cubit.play('One Two', 'Alpha Beta'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      fakeTtsService.emitWord((
        word: 'One',
        isTitle: true,
        wordIndex: 0,
        wordDurationMs: 220,
      ));
      await Future<void>.delayed(Duration.zero);
      fakeTtsService.emitWord((
        word: 'Two',
        isTitle: true,
        wordIndex: 1,
        wordDurationMs: 220,
      ));
      await Future<void>.delayed(Duration.zero);
      fakeTtsService.emitWord((
        word: 'Alpha',
        isTitle: false,
        wordIndex: 0,
        wordDurationMs: 220,
      ));
      await Future<void>.delayed(Duration.zero);
      fakeTtsService.emitWord((
        word: 'Beta',
        isTitle: false,
        wordIndex: 1,
        wordDurationMs: 220,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(wordsSeen.map((w) => w.word), ['One', 'Two', 'Alpha', 'Beta']);
      expect(cubit.state.currentWord?.word, 'Beta');

      fakeTtsService.triggerPlaybackComplete();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentWord, isNull);
      expect(cubit.state.isPlaying, false);
    });

    test('service failure: state reset, error rethrown, subsequent play recovers',
        () async {
      fakeTtsService.shouldThrow = true;

      await expectLater(
        cubit.play('Title', 'Desc'),
        throwsA(isA<Exception>()),
      );

      expect(cubit.state.isLoading, false);
      expect(cubit.state.isPlaying, false);
      expect(cubit.state.currentWord, isNull);

      fakeTtsService.shouldThrow = false;
      fakeTtsService.completeImmediately = false;

      unawaited(cubit.play('Recover', 'Works'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(cubit.state.isPlaying, true);
      expect(cubit.state.isLoading, false);
    });
  });
}
