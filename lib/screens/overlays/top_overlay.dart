import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/settings/settings_screen.dart';
import 'package:colosynth/screens/overlays/player_progress_overlay.dart';
import 'package:colosynth/screens/overlays/top_bar/currency_pill.dart';
import 'package:colosynth/screens/overlays/top_bar/level_exp_chip.dart';
import 'package:colosynth/screens/overlays/top_bar/synth_key_pill.dart';

export 'top_bar/currency_pill.dart';
export 'top_bar/level_exp_chip.dart';
export 'top_bar/synth_key_pill.dart';

class TopOverlay extends ConsumerWidget {
  const TopOverlay({
    super.key,
    required this.visible,
    this.onInkAdd,
    this.onPaintAdd,
    this.onSynthKeyTap,
    this.animateInk = false,
    this.animatePaint = false,
    this.animateXp = false,
  });

  final bool visible;
  final VoidCallback? onInkAdd;
  final VoidCallback? onPaintAdd;
  final VoidCallback? onSynthKeyTap;
  final bool animateInk;
  final bool animatePaint;
  final bool animateXp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = ref.watch(inkProvider);
    final paint = ref.watch(paintProvider);
    final synthKeys = ref.watch(synthKeysProvider);
    final levelData = ref.watch(accountLevelProvider);
    final level = levelData.accountLevel;
    final xp = levelData.accountXp;

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.paperWhite,
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: NotebookBackground()),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LevelExpChip(
                        level: level,
                        xp: xp,
                        animateGain: animateXp,
                        onTap: () {
                          PlayerProgressOverlay.show(
                            context,
                            level: level,
                            xp: xp,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CurrencyPill(
                                  icon: Icons.water_drop,
                                  color: const Color(0xFF1565C0),
                                  amount: ink,
                                  onAdd: onInkAdd,
                                  animateGain: animateInk,
                                ),
                                const SizedBox(width: 4),
                                CurrencyPill(
                                  icon: Icons.brush,
                                  color: const Color(0xFFE91E63),
                                  amount: paint,
                                  onAdd: onPaintAdd,
                                  animateGain: animatePaint,
                                ),
                                const SizedBox(width: 4),
                                SynthKeyPill(
                                  keys: synthKeys,
                                  onTap: onSynthKeyTap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const _TopSettingsButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSettingsButton extends StatefulWidget {
  const _TopSettingsButton();

  @override
  State<_TopSettingsButton> createState() => _TopSettingsButtonState();
}

class _TopSettingsButtonState extends State<_TopSettingsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        ComicButton.playButtonSfx();
        SettingsOverlay.show(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 32,
        height: 32,
        transform: _pressed
            ? Matrix4.translationValues(1.5, 1.5, 0)
            : Matrix4.translationValues(0, 0, 0),
        decoration: BoxDecoration(
          color: AppColors.paperWhite,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.8),
          boxShadow: _pressed
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0xFF1A1A1A),
                    offset: Offset(2, 2),
                  ),
                ],
        ),
        child: const Center(
          child: Icon(
            Icons.settings,
            size: 17,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
