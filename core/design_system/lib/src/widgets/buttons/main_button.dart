import 'dart:ui';

import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/src/utils/animated_press_mixin.dart';
import 'package:flutter/material.dart';

enum MainButtonMode {
  another(height: 50, width: 120),
  audio(height: 50, width: 50);

  const MainButtonMode({required this.width, required this.height});

  final double height;
  final double width;

  BorderRadius get borderRadius =>
      this == MainButtonMode.audio
          ? BorderRadius.circular(60)
          : BorderRadius.circular(12);
}

class MainButton extends StatefulWidget {
  final String label;
  final Function onTap;
  final Function(bool)? onPlayTapped;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final MainButtonMode mode;

  /// Duration before the label appears (applies to [MainButtonMode.another]).
  /// Null uses [DelayedDisplay] default.
  final Duration? delayDuration;

  /// When non-null, controls the play/pause icon (controlled mode for TTS etc).
  final bool? isPlaying;

  /// When true, shows a loading overlay over the audio button.
  final bool? isLoading;

  /// Optional background image (e.g. selected image) at 0.3 opacity.
  final ImageProvider? backgroundImage;

  const MainButton({
    super.key,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.mode = MainButtonMode.another,
    this.delayDuration,
    this.onPlayTapped,
    this.isPlaying,
    this.isLoading,
    this.backgroundImage,
  });

  @override
  State<MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<MainButton> with AnimatedPressMixin {
  bool _playing = false;

  bool get _displayPlaying => widget.isPlaying ?? _playing;

  @override
  void onPressComplete() {
    if(widget.isLoading == true){
      return; 
    }
    widget.mode == MainButtonMode.another ? widget.onTap() : _togglePlaying();
  }
      

  void _togglePlaying() {
    if (widget.isLoading == true) return;
    if (widget.onPlayTapped == null) return;
    if (widget.isPlaying != null) {
      widget.onPlayTapped!(!_displayPlaying);
    } else {
      setState(() => _playing = !_playing);
      widget.onPlayTapped!(_playing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor =
        widget.backgroundColor ?? theme.colorScheme.onSecondary;
    final foregroundColor =
        widget.foregroundColor ??
        theme.textTheme.labelLarge?.color ??
        Colors.black;

    // Build a simple vertical gradient using the backgroundColor
    // From backgroundColor (top) to backgroundColor with 70% opacity (bottom)
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [backgroundColor, backgroundColor.withValues(alpha: 0.8)],
    );

    return buildPressable(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: widget.mode.width,
        height: widget.mode.height,
        decoration: BoxDecoration(
          gradient: gradient,
          border: Border.all(color: foregroundColor),
          image: widget.backgroundImage != null
              ? DecorationImage(
                  image: widget.backgroundImage!,
                  opacity: 0.3,
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.18),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: widget.mode.borderRadius,
        ),
        child: Center(
          child: widget.mode == MainButtonMode.another
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 0),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: DelayedDisplay(
                    delay: const Duration(milliseconds: 100),
                    slidingBeginOffset: Offset(0, 0),
                    child: Text(
                      widget.label,
                      key: const ValueKey('button_label_another'),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                )
              : widget.isLoading == true
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                foregroundColor.withValues(alpha: 0.8),
                              ),
                            ),
                          )
                        : Icon(
                            !_displayPlaying
                                ? Icons.play_arrow
                                : Icons.pause_sharp,
                            key: ValueKey('audio_${_displayPlaying}'),
                          ),
        ),
      ),
    );
  }
}
