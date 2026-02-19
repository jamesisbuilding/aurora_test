/// Emitted during TTS playback: word text, whether it's from title or description,
/// and its index within that segment (for highlighting).
typedef TtsCurrentWord = ({
  String word,
  bool isTitle,
  int wordIndex,
  int wordDurationMs,
});
