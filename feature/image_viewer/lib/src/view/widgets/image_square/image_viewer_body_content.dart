import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/widgets/text/animated_text_fill.dart';
import 'package:tts_service/tts_service.dart';

/// Builds title, description, and paragraph-separator content for [ImageViewerBody].
/// Extracted for testability and separation of concerns.
class ImageViewerBodyContent {
  ImageViewerBodyContent._();
  static const _subtitleAnimDuration = Duration(milliseconds: 220);
  static const _minWordAnimDuration = Duration(milliseconds: 80);

  static Color _resolveActiveWordColor(BuildContext context, ImageModel image) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? image.lightestColor : image.darkestColor;
  }

  static Duration _resolveWordDuration(TtsCurrentWord? currentWord, bool isActive) {
    if (!isActive || currentWord == null) return _subtitleAnimDuration;
    final ms = currentWord.wordDurationMs;
    if (ms <= 0) return _subtitleAnimDuration;
    final resolved = Duration(milliseconds: ms);
    return resolved < _minWordAnimDuration ? _minWordAnimDuration : resolved;
  }

  static InlineSpan _animatedWordSpan({
    required String word,
    required TextStyle baseStyle,
    required bool isActive,
    required Color activeColor,
    required String keySeed,
    required Duration duration,
  }) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: AnimatedSubtitleWord(
        key: ValueKey(keySeed),
        text: word,
        baseStyle: baseStyle,
        activeColor: activeColor,
        isActive: isActive,
        duration: duration,
      ),
    );
  }

  /// 6×6 circle with palette color and onSurface border, for gaps between paragraphs.
  static Widget buildParagraphSeparatorCircle(
    BuildContext context,
    ImageModel image,
    int gapIndex,
  ) {
    final theme = Theme.of(context);
    final palette = image.colorPalette;
    final color = palette.isEmpty
        ? theme.colorScheme.primary
        : palette[gapIndex % palette.length];
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: theme.colorScheme.onSurface, width: 0.25),
      ),
    );
  }

  /// Builds the description content as a flat list of blocks (text, dot, text, dot...).
  static List<Widget> buildDescriptionBlocks(
    BuildContext context,
    ImageModel image,
    TtsCurrentWord? currentWord,
  ) {
    final text = image.description;
    if (text.trim().isEmpty) {
      return [Text(text, textAlign: TextAlign.center)];
    }
    final paragraphs = text
        .split('.')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (paragraphs.length <= 1) {
      return [
        buildSingleParagraphSpans(context, text, false, image, currentWord, 0),
      ];
    }
    final baseStyle = imageBodyTextStyle(
      context,
      Theme.of(context).colorScheme.onSurface,
    );
    final activeSubtitleColor = _resolveActiveWordColor(context, image);
    final blocks = <Widget>[];
    var wordIndex = 0;
    var gapIndex = 0;

    for (var p = 0; p < paragraphs.length; p++) {
      final para = paragraphs[p];
      final spans = <InlineSpan>[];
      final paraParts = RegExp(
        r'(\S+)|(\s+)',
      ).allMatches(para).map((m) => m.group(0)!).toList();
      for (var i = 0; i < paraParts.length; i++) {
        final part = paraParts[i];
        if (part.trim().isEmpty) {
          spans.add(TextSpan(text: part, style: baseStyle));
        } else {
          final match =
              currentWord != null &&
              currentWord.isTitle == false &&
              currentWord.wordIndex == wordIndex;
          spans.add(_animatedWordSpan(
            word: part,
            baseStyle: baseStyle,
            isActive: match,
            activeColor: activeSubtitleColor,
            keySeed: '${image.uid}_body_$wordIndex',
            duration: _resolveWordDuration(currentWord, match),
          ));
          wordIndex++;
        }
      }
      spans.add(TextSpan(text: '.', style: baseStyle));
      blocks.add(
        RichText(textAlign: TextAlign.center, text: TextSpan(style: baseStyle, children: spans)),

        // RepaintBoundary(
        //   child: Stack(
        //     children: [
        //       Transform.translate(
        //         offset: gapIndex % 2 == 0 ? const Offset(100, 0) : const Offset(-100, 0),

        //         child: IntrinsicHeight(
        //           child: Container(
        //             padding: .all(12),
        //             color:  Theme.of(
        //               context,
        //             ).colorScheme.onPrimary.withValues(alpha: 0.5),
        //             child: Opacity(
        //               opacity: 0,
        //               child: RichText(
        //                 textAlign: gapIndex % 2 == 0
        //                     ? TextAlign.left
        //                     : TextAlign.right,
        //                 text: TextSpan(style: baseStyle, children: spans),
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //       ClipRRect(
        //         child: BackdropFilter(
        //           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        //           child: Container(
        //             color: Theme.of(
        //               context,
        //             ).colorScheme.onPrimary.withValues(alpha: 0.5),
        //             padding: .all(12),
        //             child:
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      );

      if (p < paragraphs.length - 1) {
        blocks.add(buildParagraphSeparatorCircle(context, image, gapIndex));
        gapIndex++;
        if (gapIndex > 5) gapIndex = 0;
      }
    }
    return blocks;
  }

  static Widget buildTitleText(
    BuildContext context,
    String text,
    ImageModel image,
    TtsCurrentWord? currentWord,
  ) {
    final parts = RegExp(
      r'(\S+)|(\s+)',
    ).allMatches(text).map((m) => m.group(0)!).toList();
    if (parts.isEmpty) return Text(text, textAlign: TextAlign.center);
    final baseStyle = imageTitleTextStyle(context).copyWith(height: 1.15);
    final activeTitleColor = _resolveActiveWordColor(context, image);
    final spans = <InlineSpan>[];
    var wordIndex = 0;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.trim().isEmpty) {
        spans.add(TextSpan(text: part, style: baseStyle));
      } else {
        final match =
            currentWord != null &&
            currentWord.isTitle == true &&
            currentWord.wordIndex == wordIndex;
        spans.add(_animatedWordSpan(
          word: part,
          baseStyle: baseStyle,
          isActive: match,
          activeColor: activeTitleColor,
          keySeed: '${image.uid}_title_$wordIndex',
          duration: _resolveWordDuration(currentWord, match),
        ));
        wordIndex++;
      }
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  static Widget buildSingleParagraphSpans(
    BuildContext context,
    String text,
    bool isTitle,
    ImageModel image,
    TtsCurrentWord? currentWord,
    int index,
  ) {
    final parts = RegExp(
      r'(\S+)|(\s+)',
    ).allMatches(text).map((m) => m.group(0)!).toList();
    if (parts.isEmpty) return Text(text, textAlign: TextAlign.center);
    final baseStyle = isTitle
        ? imageTitleTextStyle(context).copyWith(height: 1.15)
        : imageBodyTextStyle(context, Theme.of(context).colorScheme.onSurface);
    final activeColor = _resolveActiveWordColor(context, image);
    final spans = <InlineSpan>[];
    var wordIndex = 0;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.trim().isEmpty) {
        spans.add(TextSpan(text: part, style: baseStyle));
      } else {
        final match =
            currentWord != null &&
            currentWord.isTitle == isTitle &&
            currentWord.wordIndex == wordIndex;
        spans.add(_animatedWordSpan(
          word: part,
          baseStyle: baseStyle,
          isActive: match,
          activeColor: activeColor,
          keySeed: '${image.uid}_${isTitle ? 'title' : 'body'}_${index}_$wordIndex',
          duration: _resolveWordDuration(currentWord, match),
        ));
        wordIndex++;
      }
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
