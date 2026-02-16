import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:tts_service/tts_service.dart';

/// Builds title, description, and paragraph-separator content for [ImageViewerBody].
/// Extracted for testability and separation of concerns.
class ImageViewerBodyContent {
  ImageViewerBodyContent._();

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
        border: Border.all(
          color: theme.colorScheme.onSurface,
          width: 0.25,
        ),
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
    final paragraphs =
        text.split('.').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (paragraphs.length <= 1) {
      return [buildSingleParagraphSpans(context, text, false, image, currentWord)];
    }
    final theme = Theme.of(context);
    final baseStyle = imageBodyTextStyle(context, Theme.of(context).colorScheme.onSurface);
    final highlightBg = theme.colorScheme.onSurface;
    final highlightFg = theme.colorScheme.surface;
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: highlightBg.withAlpha((0.5 * 255).toInt()),
      color: highlightFg,
    );
    final blocks = <Widget>[];
    var wordIndex = 0;
    var gapIndex = 0;

    for (var p = 0; p < paragraphs.length; p++) {
      final para = paragraphs[p];
      final spans = <InlineSpan>[];
      final paraParts =
          RegExp(r'(\S+)|(\s+)').allMatches(para).map((m) => m.group(0)!).toList();
      for (var i = 0; i < paraParts.length; i++) {
        final part = paraParts[i];
        if (part.trim().isEmpty) {
          spans.add(TextSpan(text: part, style: baseStyle));
        } else {
          final match = currentWord != null &&
              currentWord.isTitle == false &&
              currentWord.wordIndex == wordIndex;
          spans.add(TextSpan(text: part, style: match ? highlightStyle : baseStyle));
          wordIndex++;
        }
      }
      spans.add(TextSpan(text: '.', style: baseStyle));
      blocks.add(
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(style: baseStyle, children: spans),
        ),
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
    final parts =
        RegExp(r'(\S+)|(\s+)').allMatches(text).map((m) => m.group(0)!).toList();
    if (parts.isEmpty) return Text(text, textAlign: TextAlign.center);
    final theme = Theme.of(context);
    final baseStyle = imageTitleTextStyle(context).copyWith(height: 1.15);
    final highlightBg = theme.colorScheme.onSurface;
    final highlightFg = theme.colorScheme.surface;
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: highlightBg.withAlpha((0.5 * 255).toInt()),
      color: highlightFg,
    );
    final spans = <InlineSpan>[];
    var wordIndex = 0;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.trim().isEmpty) {
        spans.add(TextSpan(text: part, style: baseStyle));
      } else {
        final match = currentWord != null &&
            currentWord.isTitle == true &&
            currentWord.wordIndex == wordIndex;
        spans.add(TextSpan(text: part, style: match ? highlightStyle : baseStyle));
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
  ) {
    final parts =
        RegExp(r'(\S+)|(\s+)').allMatches(text).map((m) => m.group(0)!).toList();
    if (parts.isEmpty) return Text(text, textAlign: TextAlign.center);
    final theme = Theme.of(context);
    final baseStyle = isTitle
        ? imageTitleTextStyle(context).copyWith(height: 1.15)
        : imageBodyTextStyle(context,  Theme.of(context).colorScheme.onSurface);
    final highlightBg = theme.colorScheme.onSurface;
    final highlightFg = theme.colorScheme.surface;
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: highlightBg.withAlpha((0.5 * 255).toInt()),
      color: highlightFg,
    );
    final spans = <InlineSpan>[];
    var wordIndex = 0;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.trim().isEmpty) {
        spans.add(TextSpan(text: part, style: baseStyle));
      } else {
        final match = currentWord != null &&
            currentWord.isTitle == isTitle &&
            currentWord.wordIndex == wordIndex;
        spans.add(TextSpan(text: part, style: match ? highlightStyle : baseStyle));
        wordIndex++;
      }
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
