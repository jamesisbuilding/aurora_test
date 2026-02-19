import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

PageRouteBuilder<T> slideUpRoute<T>({
  required Widget page,
  Duration transitionDuration = const Duration(milliseconds: 350),
  Duration reverseTransitionDuration = const Duration(milliseconds: 280),
  Curve curve = Curves.easeOutCubic,
  bool includeFade = false,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve));

      final transitioned = SlideTransition(position: offsetAnimation, child: child);
      if (!includeFade) return transitioned;

      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: transitioned,
      );
    },
  );
}

CustomTransitionPage<T> fadeTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Duration reverseTransitionDuration = const Duration(milliseconds: 300),
  Curve curve = Curves.easeOut,
}) {
  return CustomTransitionPage<T>(
    key: key,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: curve),
        child: pageChild,
      );
    },
  );
}
