import 'package:flutter/material.dart';

import 'package:colosynth/game/app_shell/battle_screen.dart' show BattleGameApi;
import 'package:flame/game.dart' show FlameGame;
import 'package:colosynth/game/widgets/hp_bar_widget.dart';
import 'package:colosynth/game/widgets/skill_meter_widget.dart';
import 'package:colosynth/screens/theme/tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/providers/save_provider.dart';

export 'hp_bar_widget.dart' show HpBar;

const kHudAccent = AppColors.ink;
const kHudBorder = Color(0x331A1A1A);
const kHudPanelBg = Color(0xDD2A2A2A);

class BattleHudWidget extends ConsumerStatefulWidget {
  const BattleHudWidget({super.key, required this.game, required this.onPause});

  final FlameGame game;
  final VoidCallback onPause;

  @override
  ConsumerState<BattleHudWidget> createState() => _BattleHudWidgetState();
}

class _BattleHudWidgetState extends ConsumerState<BattleHudWidget> {
  BattleGameApi? _world;

  @override
  void initState() {
    super.initState();
    widget.game.loaded.then((_) {
      if (mounted) setState(() => _world = widget.game as BattleGameApi);
    }).catchError((e) {
      debugPrint('BattleHudWidget: game load error — $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final world = _world;
    if (world == null) return const SizedBox.shrink();

    final charId = ref.watch(equippedCharacterIdProvider);
    final levelData = ref.watch(characterLevelFamily(charId));

    return _HudLayer(
      world: world,
      onPause: widget.onPause,
      level: levelData.level,
    );
  }
}

class _HudLayer extends StatelessWidget {
  const _HudLayer({
    required this.world,
    required this.onPause,
    required this.level,
  });

  final BattleGameApi world;
  final VoidCallback onPause;
  final int level;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final safeTop = padding.top;
    final safeBottom = padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: safeTop + 8,
          left: 12,
          right: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: world.enemyHpFraction,
                builder: (_, __, ___) => HpBar(
                  current: world.enemy.currentHp,
                  max: world.enemy.maxHp,
                  label: world.enemyDisplayName.toUpperCase(),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: _SideDodgeButton(
              label: '◄',
              sublabel: 'DODGE',
              onTap: () => world.onPlayerDodge(isLeft: true),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: _SideDodgeButton(
              label: '►',
              sublabel: 'DODGE',
              onTap: () => world.onPlayerDodge(isLeft: false),
            ),
          ),
        ),
        Positioned(
          top: safeTop + 8,
          right: 12,
          child: PauseButtonWidget(onTap: onPause),
        ),
        Positioned(
          left: 16,
          bottom: safeBottom + 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatChip(label: 'LV', value: level, color: kHudAccent),
              const SizedBox(height: 8),
              ValueListenableBuilder<double>(
                valueListenable: world.playerHpFraction,
                builder: (_, __, ___) => _VerticalHpBar(
                  current: world.player.currentHp,
                  max: world.player.maxHp,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: safeBottom + 8,
          child: Center(
            child: ActiveSkillMeterWidget(
              activeSkill: world.activeSkill,
              onActivate: world.onPlayerActiveSkill,
            ),
          ),
        ),
        Positioned(
          right: 72,
          bottom: safeBottom + 16,
          child: DefendButton(
            onBlockStart: world.onPlayerBlockStart,
            onBlockEnd: world.onPlayerBlockEnd,
          ),
        ),
      ],
    );
  }
}


class _VerticalHpBar extends StatelessWidget {
  const _VerticalHpBar({required this.current, required this.max});

  final int current;
  final int max;

  Color get _barColor {
    final safeMax = max < 1 ? 1 : max;
    final r = current / safeMax;
    if (r > 0.5) return AppColors.ink;
    if (r > 0.25) return AppColors.darkGray;
    return AppColors.sketchGray;
  }

  @override
  Widget build(BuildContext context) {
    final safeMax = max < 1 ? 1 : max;
    final ratio = (current / safeMax).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$current',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 13,
            color: _barColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 26,
          height: 200,
          child: CustomPaint(
            painter: _VerticalHpPainter(ratio: ratio, color: _barColor),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'HP',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _VerticalHpPainter extends CustomPainter {
  const _VerticalHpPainter({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  static const _b = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    final inner = outer.deflate(_b);

    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(4)),
      Paint()..color = const Color(0xFF111111),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(3)),
      Paint()..color = const Color(0xFF0A0A0A),
    );

    if (ratio > 0) {
      final fillH = inner.height * ratio;
      final fillRect = Rect.fromLTWH(
        inner.left,
        inner.bottom - fillH,
        inner.width,
        fillH,
      );
      canvas.save();
      canvas
          .clipRRect(RRect.fromRectAndRadius(inner, const Radius.circular(3)));
      canvas.drawRect(fillRect, Paint()..color = color);
      canvas.drawRect(
        Rect.fromLTWH(inner.left + 2, fillRect.top + 2, inner.width - 4, 3),
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
      canvas.restore();
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _b,
    );
  }

  @override
  bool shouldRepaint(_VerticalHpPainter o) =>
      o.ratio != ratio || o.color != color;
}

class _SideDodgeButton extends StatelessWidget {
  const _SideDodgeButton({
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ComicButton.playButtonSfx();
        onTap();
      },
      child: Container(
        width: 36,
        height: 72,
        decoration: BoxDecoration(
          color: kHudPanelBg,
          border: Border.all(color: kHudBorder, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 18,
                color: kHudAccent,
              ),
            ),
            Text(
              sublabel,
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 8,
                color: Colors.white54,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DefendButton extends StatefulWidget {
  const DefendButton({
    super.key,
    required this.onBlockStart,
    required this.onBlockEnd,
  });

  final VoidCallback onBlockStart;
  final VoidCallback onBlockEnd;

  @override
  State<DefendButton> createState() => _DefendButtonState();
}

class _DefendButtonState extends State<DefendButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDown(TapDownDetails _) {
    ComicButton.playButtonSfx();
    setState(() => _pressed = true);
    _ctrl.forward();
    widget.onBlockStart();
  }

  void _onUp(TapUpDetails _) {
    setState(() => _pressed = false);
    _ctrl.reverse();
    widget.onBlockEnd();
  }

  void _onCancel() {
    setState(() => _pressed = false);
    _ctrl.reverse();
    widget.onBlockEnd();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onDown,
      onTapUp: _onUp,
      onTapCancel: _onCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFF143322) : const Color(0xFF0A1A0A),
            border: Border.all(
              color:
                  _pressed ? const Color(0xCCAAFFAA) : const Color(0x55AAFFAA),
              width: _pressed ? 2.0 : 1.5,
            ),
            boxShadow: _pressed
                ? const [
                    BoxShadow(
                      color: Color(0x6600FF88),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              'DEF',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 14,
                color: _pressed
                    ? const Color(0xFFCCFFCC)
                    : const Color(0xFF88FF88),
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PauseButtonWidget extends StatelessWidget {
  const PauseButtonWidget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ComicButton.playButtonSfx();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kHudPanelBg,
          border: Border.all(color: kHudBorder, width: 1),
        ),
        child: const Icon(Icons.pause, color: kHudAccent, size: 20),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.color = Colors.white70,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 9,
              color: color.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 11,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

