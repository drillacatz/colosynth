import 'package:flutter/material.dart';
import 'package:colosynth/game/app_shell/battle_screen.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/widgets/common/app_card_container.dart';
import 'package:colosynth/widgets/common/app_comic_button.dart';

class BattlePauseWidget extends StatefulWidget {
  const BattlePauseWidget({
    super.key,
    this.game,
    this.onResume,
    this.onRestart,
    this.onQuit,
  });

  final BattleFlameGame? game;
  final VoidCallback? onResume;
  final VoidCallback? onRestart;
  final VoidCallback? onQuit;

  @override
  State<BattlePauseWidget> createState() => _BattlePauseWidgetState();
}

class _BattlePauseWidgetState extends State<BattlePauseWidget> {
  bool _showQuitConfirm = false;

  void _handleResume() {
    if (widget.onResume != null) {
      widget.onResume!();
    } else {
      widget.game?.resumeEngine();
    }
  }

  void _handleRestart() {
    if (widget.onRestart != null) {
      widget.onRestart!();
    } else {
      widget.game?.resumeEngine();
      widget.game?.resetBattle();
    }
  }

  void _handleQuit() {
    if (widget.onQuit != null) {
      widget.onQuit!();
    } else {
      Navigator.of(context, rootNavigator: true)
          .pop(BattleResult.empty(BattleOutcome.quit));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showQuitConfirm) {
          setState(() => _showQuitConfirm = false);
        } else {
          _handleResume();
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _showQuitConfirm
                    ? _buildQuitConfirmView()
                    : _buildPauseMenuView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseMenuView() {
    return Column(
      key: const ValueKey('pause_menu'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'PAUSED',
          style: TextStyle(
            fontFamily: 'Bangers',
            color: Color(0xFFFF4444),
            fontSize: 52,
            letterSpacing: 8,
            shadows: [
              Shadow(color: Color(0xFFE53935), blurRadius: 20),
              Shadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 160,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFFE53935).withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        AppComicButton(
          label: 'RESUME',
          style: AppButtonStyle.accent,
          width: 220,
          height: 52,
          fontSize: 18,
          onTap: _handleResume,
        ),
        const SizedBox(height: 14),
        AppComicButton(
          label: 'RESTART',
          style: AppButtonStyle.white,
          width: 220,
          height: 50,
          fontSize: 16,
          onTap: _handleRestart,
        ),
        const SizedBox(height: 14),
        AppComicButton(
          label: 'QUIT',
          style: AppButtonStyle.dark,
          width: 220,
          height: 50,
          fontSize: 16,
          onTap: () => setState(() => _showQuitConfirm = true),
        ),
      ],
    );
  }

  Widget _buildQuitConfirmView() {
    return AppCardContainer(
      key: const ValueKey('quit_confirm'),
      width: 320,
      style: PBStyle.dark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE53935), width: 2),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE53935),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ABANDON BATTLE?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 28,
              letterSpacing: 3,
              color: AppColors.pureWhite,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Current match progress and rewards will be forfeited.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          AppComicButton(
            label: 'KEEP FIGHTING',
            style: AppButtonStyle.accent,
            width: double.infinity,
            height: 48,
            fontSize: 16,
            onTap: () => setState(() => _showQuitConfirm = false),
          ),
          const SizedBox(height: 12),
          AppComicButton(
            label: 'QUIT BATTLE',
            style: AppButtonStyle.dark,
            width: double.infinity,
            height: 48,
            fontSize: 15,
            onTap: _handleQuit,
          ),
        ],
      ),
    );
  }
}
