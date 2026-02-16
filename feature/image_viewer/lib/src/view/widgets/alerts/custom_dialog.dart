import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showCustomDialog({
  required BuildContext context,
  required String message,
  required VoidCallback onDismiss,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    HapticFeedback.heavyImpact();
    showGeneralDialog(
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final bounceAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: bounceAnimation,
          child: _GlassmorphicDialog(
            message: message,
            onDismiss: onDismiss,
          ),
        );
      },
    );
  });
}

class _GlassmorphicDialog extends StatelessWidget {
  const _GlassmorphicDialog({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
     final isLight = Theme.of(context).brightness == Brightness.light;
    // Inverted: light mode → dark popup; dark mode → light popup
    final fillColor = isLight
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.25);
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: DefaultTextStyle(
                style: CupertinoTheme.of(context)
                    .textTheme
                    .textStyle
                    .copyWith(
                      color: textColor,
                      fontFamily: 'Raleway',
                      package: 'design_system',
                    ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        onDismiss();
                      },
                      child: Text('OK', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
