import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:tts_service/tts_service.dart';

class ImageViewerBody extends StatelessWidget {
  final String title;
  final String description;
  final List<Color> colorPalette;
  final TtsCurrentWord? currentWord;
  final Color? lightestColor;
  final Color? darkestColor;

  const ImageViewerBody({
    super.key,
    required this.title,
    required this.description,
    required this.colorPalette,
    this.currentWord,
    this.lightestColor,
    this.darkestColor,
  });

  List<String> _words(String text) =>
      text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

  Widget _buildHighlightableText(
    BuildContext context,
    String text,
    bool isTitle,
  ) {
    final words = _words(text);
    if (words.isEmpty) return Text(text, textAlign: TextAlign.center);
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle();

    final highlightBg = theme.colorScheme.onSurface;
    final highlightFg = theme.colorScheme.surface;
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: highlightBg.withValues(alpha: 0.5),
      color: highlightFg,
    );
    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      final match =
          currentWord != null &&
          currentWord!.isTitle == isTitle &&
          currentWord!.wordIndex == i;
      spans.add(
        TextSpan(text: words[i], style: match ? highlightStyle : baseStyle),
      );
      if (i < words.length - 1)
        spans.add(TextSpan(text: ' ', style: baseStyle));
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DelayedDisplay(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: _buildHighlightableText(context, title, true),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(colorPalette.length, (index) {
            return DelayedDisplay(
              delay: Duration(milliseconds: 100 * index),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: colorPalette[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        DelayedDisplay(
          delay: const Duration(milliseconds: 600),
          slidingBeginOffset: const Offset(0, 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: _buildHighlightableText(context, description, false),
          ),
        ),
      ],
    );
  }
}
