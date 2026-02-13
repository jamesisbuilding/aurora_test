import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/widgets/image_square/palette_explosion.dart';
import 'package:tts_service/tts_service.dart';

class ImageViewerBody extends StatelessWidget {
  final ImageModel image; 
  final TtsCurrentWord? currentWord;
 
  final Function(bool) onColorsExpanded;
  final bool visible;

  const ImageViewerBody({
    super.key,
    required this.image, 
    required this.onColorsExpanded,
    required this.visible,
    this.currentWord,

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
      backgroundColor: highlightBg.withAlpha((0.5 * 255).toInt()),
      color: highlightFg,
    );
    final spans = <InlineSpan>[];

    if (isTitle) {
      spans.add(TextSpan(text: '"', style: baseStyle));
    }

    for (var i = 0; i < words.length; i++) {
      final match =
          currentWord != null &&
          currentWord!.isTitle == isTitle &&
          currentWord!.wordIndex == i;
      spans.add(
        TextSpan(text: words[i], style: match ? highlightStyle : baseStyle),
      );
      if (i < words.length - 1) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }
    }

    if (isTitle) {
      spans.add(TextSpan(text: '"', style: baseStyle));
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
        AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: DelayedDisplay(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: _buildHighlightableText(context, image.title, true),
            ),
          ),
        ),

        PaletteInteraction(
          colors: image.colorPalette,
          image: image,
          onChanged: (expanded) => onColorsExpanded(expanded),
        ),

        AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: DelayedDisplay(
            delay: const Duration(milliseconds: 600),
            slidingBeginOffset: const Offset(0, 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: _buildHighlightableText(context, image.description, false),
            ),
          ),
        ),
      ],
    );
  }
}
