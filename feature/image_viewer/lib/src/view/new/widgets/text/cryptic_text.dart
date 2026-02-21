import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CryptoText
//
// A widget that animates a string by cycling each character through random
// glyphs before "resolving" to its final value. Characters resolve from left
// to right (or all at once in burst mode), each spending a configurable number
// of frames scrambled before locking in.
//
// Usage:
//
//   CryptoText(
//     'Hello World',
//     style: TextStyle(fontSize: 32, fontFamily: 'JetBrains Mono'),
//     speed: CryptoTextSpeed.normal,
//     mode: CryptoTextMode.cascade,
//   )
//
// To retrigger the animation, change the `key`:
//
//   CryptoText('New message', key: ValueKey(someCounter))
//
// ─────────────────────────────────────────────────────────────────────────────

// ── Public enums ──────────────────────────────────────────────────────────────

/// How fast each character scrambles before resolving.
enum CryptoTextSpeed {
  /// 16ms tick — cinematic, slow reveal
  cinematic,

  /// 40ms tick — deliberate, readable
  slow,

  /// 24ms tick — default, snappy
  normal,

  /// 12ms tick — rapid fire
  fast,

  /// 6ms tick — frantic
  frantic,
}

extension _CryptoTextSpeedMs on CryptoTextSpeed {
  int get tickMs {
    switch (this) {
      case CryptoTextSpeed.cinematic:
        return 80;
      case CryptoTextSpeed.slow:
        return 50;
      case CryptoTextSpeed.normal:
        return 28;
      case CryptoTextSpeed.fast:
        return 14;
      case CryptoTextSpeed.frantic:
        return 7;
    }
  }
}

/// Controls the reveal pattern.
enum CryptoTextMode {
  /// Characters resolve left-to-right, one at a time.
  cascade,

  /// All characters scramble simultaneously, then resolve left-to-right.
  burst,

  /// Characters resolve in random order.
  random,

  /// Characters resolve right-to-left.
  reverse,
}

// ── Glyph sets ────────────────────────────────────────────────────────────────

// The scramble pool — drawn from to fake cryptographic noise.
// Layered: symbols first (most alien), then digits, then mixed-case latin.
const String _kSymbols = r'!@#$%^&*()-_=+[]{}|;:<>?,./~`\"';
const String _kDigits = '0123456789';
const String _kLatinUC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _kLatinLC = 'abcdefghijklmnopqrstuvwxyz';
const String _kCyrillic = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';
const String _kGreek = 'ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθ';
const String _kBraille = '⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟';

// Full scramble alphabet — used in the early frames of each character.
final String _kFullAlphabet =
    _kSymbols +
    _kDigits +
    _kLatinUC +
    _kLatinLC +
    _kCyrillic +
    _kGreek +
    _kBraille;

// Narrowed alphabet — used in the final frames before resolving.
// Similar characters to the target, so the last few cycles feel like
// the character is almost-but-not-quite finding itself.
String _narrowAlphabetFor(String targetChar) {
  if (_kLatinUC.contains(targetChar)) return _kLatinUC + _kDigits;
  if (_kLatinLC.contains(targetChar)) return _kLatinLC + _kDigits;
  if (_kDigits.contains(targetChar)) return _kDigits + _kSymbols;
  return _kFullAlphabet;
}

// ── Per-character state ───────────────────────────────────────────────────────

class _CharState {
  final String target; // the real character
  bool resolved = false; // has it locked in?
  String current = ' '; // what is currently displayed
  int framesLeft = 0; // frames until resolve
  int totalFrames = 0; // total scramble frames assigned

  _CharState(this.target, {required int scrambleFrames})
    : framesLeft = scrambleFrames,
      totalFrames = scrambleFrames,
      current = target == ' ' ? ' ' : _randomGlyph(_kFullAlphabet);

  bool get isSpace => target == ' ';
}

String _randomGlyph(String alphabet, [Random? rng]) {
  final r = rng ?? Random();
  return alphabet[r.nextInt(alphabet.length)];
}

// ── CryptoText widget ─────────────────────────────────────────────────────────

class CryptoText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final CryptoTextSpeed speed;
  final CryptoTextMode mode;

  /// How many scramble frames each character goes through before resolving.
  /// Null = auto-calculated based on string length.
  final int? scrambleFrames;

  /// Delay before the animation begins.
  final Duration initialDelay;

  /// Called when all characters have resolved.
  final VoidCallback? onComplete;

  /// Colour of unresolved (scrambled) characters.
  /// Defaults to 40% opacity of the text colour.
  final Color? scrambleColor;

  const CryptoText(
    this.text, {
    super.key,
    this.style,
    this.speed = CryptoTextSpeed.normal,
    this.mode = CryptoTextMode.cascade,
    this.scrambleFrames,
    this.initialDelay = Duration.zero,
    this.onComplete,
    this.scrambleColor,
  });

  @override
  State<CryptoText> createState() => _CryptoTextState();
}

class _CryptoTextState extends State<CryptoText> {
  final Random _rng = Random();
  late List<_CharState> _chars;
  Timer? _ticker;
  Timer? _delayTimer;
  bool _complete = false;

  // In cascade/reverse: index of the character currently "unlocking"
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _delayTimer?.cancel();
    super.dispose();
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  void _init() {
    _complete = false;
    _activeIndex = widget.mode == CryptoTextMode.reverse
        ? widget.text.length - 1
        : 0;

    // Total animation budget: 2000ms
    // Tick interval comes from speed enum.
    // frames available = 2000 / tickMs
    final int totalFrames = (2000 / widget.speed.tickMs).floor().clamp(10, 999);

    // Each character gets a scrambleFrames value that is its RESOLVE frame —
    // i.e. which frame it locks in on. All chars are visible and scrambling
    // from frame 1. They resolve staggered across the 2-second window
    // according to mode.
    final int nonSpaceCount = widget.text.characters
        .where((c) => c != ' ')
        .length;

    // Build per-character state — ALL start scrambling immediately
    int nonSpaceIndex = 0;
    _chars = widget.text.characters.map((c) {
      if (c == ' ') {
        return _CharState(c, scrambleFrames: 0);
      }

      final int resolveFrame = _resolveFrame(
        charIndex: nonSpaceIndex,
        totalChars: nonSpaceCount,
        totalFrames: totalFrames,
        mode: widget.mode,
      );
      nonSpaceIndex++;

      return _CharState(c, scrambleFrames: resolveFrame);
    }).toList();

    // Spaces resolve immediately
    for (final ch in _chars) {
      if (ch.isSpace) ch.resolved = true;
    }

    if (widget.initialDelay == Duration.zero) {
      _startTicker();
    } else {
      _delayTimer = Timer(widget.initialDelay, _startTicker);
    }
  }

  /// Returns the frame number at which character [charIndex] should resolve.
  /// All characters are scrambling from frame 0 — this just determines
  /// when each one locks to its final value.
  int _resolveFrame({
    required int charIndex,
    required int totalChars,
    required int totalFrames,
    required CryptoTextMode mode,
  }) {
    if (totalChars == 0) return totalFrames;

    // Minimum scramble: at least 30% of total frames so nothing resolves too fast
    final int minFrame = (totalFrames * 0.30).floor();
    // Last character resolves at 95% of total so there's a tiny tail
    final int maxFrame = (totalFrames * 0.95).floor();
    final int range = maxFrame - minFrame;

    switch (mode) {
      case CryptoTextMode.cascade:
        // Linear stagger left to right
        return minFrame +
            ((charIndex / (totalChars - 1).clamp(1, 9999)) * range).floor();

      case CryptoTextMode.reverse:
        // Linear stagger right to left
        final reversedIndex = (totalChars - 1) - charIndex;
        return minFrame +
            ((reversedIndex / (totalChars - 1).clamp(1, 9999)) * range).floor();

      case CryptoTextMode.burst:
        // All resolve at the same moment — end of the window
        return maxFrame;

      case CryptoTextMode.random:
        // Random resolve time within the window
        return minFrame + _rng.nextInt(range.clamp(1, 9999));
    }
  }

  // ── Tick ──────────────────────────────────────────────────────────────────

  // Global frame counter — incremented every tick.
  // Each character has a resolveFrame (stored in framesLeft at init as a
  // target frame number, not a countdown). We compare _frame to ch.framesLeft.
  int _frame = 0;

  void _startTicker() {
    _frame = 0;
    _ticker = Timer.periodic(
      Duration(milliseconds: widget.speed.tickMs),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (!mounted) return;
    _frame++;

    setState(() {
      bool anyUnresolved = false;

      for (final ch in _chars) {
        if (ch.resolved || ch.isSpace) continue;

        anyUnresolved = true;

        // Has this character reached its resolve frame?
        if (_frame >= ch.framesLeft) {
          ch.current = ch.target;
          ch.resolved = true;
          continue;
        }

        // Still scrambling — narrow alphabet in final 30% of THIS char's window
        final double progress = _frame / ch.framesLeft;
        final String alphabet = progress > 0.70
            ? _narrowAlphabetFor(ch.target)
            : _kFullAlphabet;

        ch.current = _randomGlyph(alphabet, _rng);
      }

      if (!anyUnresolved) _finish();
    });
  }

  void _finish() {
    _ticker?.cancel();
    _ticker = null;
    if (!_complete) {
      _complete = true;
      // Ensure all characters show their final value
      for (final ch in _chars) {
        ch.current = ch.target;
        ch.resolved = true;
      }
      widget.onComplete?.call();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final resolvedColor = baseStyle.color ?? Colors.white;
    final scrambleColor =
        widget.scrambleColor ?? resolvedColor.withOpacity(0.38);

    // Build a RichText so resolved and unresolved chars can have
    // different colours / weights
    final spans = <InlineSpan>[];

    for (int i = 0; i < _chars.length; i++) {
      final ch = _chars[i];

      // Determine if this char is "active" (currently scrambling)
      final bool isActive = !ch.resolved && !ch.isSpace;

      // Resolved chars: full colour, normal weight
      // Active chars: scramble colour, monospace feel via slight weight bump
      final TextStyle charStyle = isActive
          ? baseStyle.copyWith(
              color: scrambleColor,
              
              // fontFeatures: const [FontFeature.tabularFigures()],
            )
          : baseStyle.copyWith(color: resolvedColor);

      spans.add(
        TextSpan(text: ch.isSpace ? ' ' : ch.current, style: charStyle),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      
      overflow: TextOverflow.ellipsis,
    );
  }
}



class CryptoTextController extends ChangeNotifier {
  _CryptoTextState? _state;

  /// Restart the animation from scratch.
  void retrigger() {
    _state?._init();
    notifyListeners();
  }

  /// Immediately resolve all characters to their final values.
  void skip() {
    _state?._finish();
    notifyListeners();
  }
}
