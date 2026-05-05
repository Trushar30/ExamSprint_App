import 'package:flutter/material.dart';

class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlideRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.05, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var scaleTween = Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return ScaleTransition(
              scale: scaleTween,
              child: FadeTransition(
                opacity: fadeTween,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        );
}

class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool forward;

  SharedAxisRoute({required this.page, this.forward = true})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final begin = forward ? const Offset(0.0, 0.05) : const Offset(0.0, -0.05);
            final end = Offset.zero;
            
            var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: fadeTween,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
