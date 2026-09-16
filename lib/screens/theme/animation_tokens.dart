import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';












class AppAnimations {
  AppAnimations._();


  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration entrance = Duration(milliseconds: 600);
  static const Duration staggeredDelay = Duration(milliseconds: 50);


  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve entranceCurve = Curves.easeOutBack;




  static Animate entranceFadeScale(Widget child, {Duration? delay}) {
    return child
        .animate(delay: delay ?? Duration.zero)
        .fadeIn(duration: fast, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: medium,
          curve: entranceCurve,
        );
  }


  static Animate staggeredEntrance(Widget child, int index, {Duration? delay}) {
    final finalDelay = (delay ?? Duration.zero) + (staggeredDelay * index);
    return child
        .animate(delay: finalDelay)
        .fadeIn(duration: fast)
        .slideY(begin: 0.1, end: 0, duration: medium, curve: standardCurve);
  }





  static Animate overlayEntrance(Widget child) {
    return child.animate().fadeIn(duration: fast, curve: Curves.easeOut).scale(
          begin: const Offset(0.82, 0.82),
          end: const Offset(1.0, 1.0),
          duration: entrance,
          curve: bouncyCurve,
        );
  }


  static Animate dividerEntrance(Widget child, {Duration? delay}) {
    return child
        .animate(delay: delay ?? fast)
        .fadeIn(duration: fast)
        .slideX(begin: -0.06, end: 0, duration: medium, curve: standardCurve);
  }


  static Animate buttonEntrance(Widget child, {Duration? delay}) {
    return child.animate(delay: delay ?? medium).fadeIn(duration: fast).slideY(
          begin: 0.15,
          end: 0,
          duration: medium,
          curve: entranceCurve,
        );
  }


  static Animate labelEntrance(Widget child, {Duration? delay}) {
    return child
        .animate(delay: delay ?? medium)
        .fadeIn(duration: medium, curve: standardCurve);
  }
}



extension AppAnimateExtension on Widget {

  Animate animateEntrance({Duration? delay}) =>
      AppAnimations.entranceFadeScale(this, delay: delay);


  Animate animateStaggered(int index, {Duration? delay}) =>
      AppAnimations.staggeredEntrance(this, index, delay: delay);


  Animate animateOverlay() => AppAnimations.overlayEntrance(this);


  Animate animateDivider({Duration? delay}) =>
      AppAnimations.dividerEntrance(this, delay: delay);


  Animate animateButton({Duration? delay}) =>
      AppAnimations.buttonEntrance(this, delay: delay);


  Animate animateLabel({Duration? delay}) =>
      AppAnimations.labelEntrance(this, delay: delay);
}
