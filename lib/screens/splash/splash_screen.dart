import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:colosynth/services/sprite_repository.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/screens/title/title_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    AudioService.instance.playBgm(BgmTrack.splash);
    _ctrl = AnimationController(vsync: this);

    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (!_navigated) _navigate();
    });
  }

  void _onLottieLoaded(LottieComposition composition) {
    _ctrl.duration = composition.duration;
    _ctrl.forward().whenComplete(_navigate);
  }

  void _navigate() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const TitleScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080400),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Lottie.asset(
            SpriteRepository.splashLottie,
            controller: _ctrl,
            onLoaded: _onLottieLoaded,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              _navigate();
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
