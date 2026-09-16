import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_data/level_data.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/tier_chest_provider.dart';
import 'package:colosynth/screens/tournament/battle_flow.dart';
import 'package:colosynth/screens/level/tier_chest_overlay.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/widgets/common/animated_tap_button.dart';

class LevelScreen extends ConsumerStatefulWidget {
  const LevelScreen({
    super.key,
    required this.tournament,
    required this.style,
  });

  final TournamentData tournament;
  final ArenaStyle style;

  static Future<void> push(
    BuildContext context, {
    required TournamentData tournament,
    required ArenaStyle style,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            LevelScreen(tournament: tournament, style: style),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  static const _flow = TournamentBattleFlow();

  bool get _isDark => widget.style == ArenaStyle.darkComic;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(tournamentProgressProvider);
    final chestState = ref.watch(tierChestProvider(widget.tournament.tier));

    final stages = widget.tournament.stages;

    final bgColor = _isDark ? const Color(0xFF0D0600) : Colors.white;
    final accent = widget.tournament.accentColor;

    int claimableCount = 0;
    for (int r = 0; r < 6; r++) {
      if (!chestState.claimed[r] &&
          isMilestoneCleared(widget.tournament.tier, r, progress)) {
        claimableCount++;
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            if (!_isDark) Positioned.fill(child: _LightPaperTexture()),
            if (_isDark) Positioned.fill(child: _DarkInkTexture()),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 52),
                  _LevelHeader(
                    tier: widget.tournament.tier,
                    name: widget.tournament.name,
                    recLv: widget.tournament.recLv,
                    accent: accent,
                    isDark: _isDark,
                    onBack: () {
                      playSfx();
                      Navigator.of(context).pop();
                    },
                  )
                      .animate()
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: -0.06, end: 0, duration: 280.ms),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: stages.length,
                      itemBuilder: (ctx, stageIdx) {
                        final stage = stages[stageIdx];
                        final globalDelay = stageIdx * 60;
                        return _StageBlock(
                          stage: stage,
                          progress: progress,
                          isDark: _isDark,
                          accent: accent,
                          delayBase: globalDelay,
                          onFight: (slot) => _flow.fight(
                            context: context,
                            ref: ref,
                            slot: slot,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 24,
              right: 20,
              child: _ChestFab(
                claimableCount: claimableCount,
                isDark: _isDark,
                accent: accent,
                onTap: () => _openChestOverlay(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChestOverlay(BuildContext context) {
    playSfx();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TierChestOverlay(
        tier: widget.tournament.tier,
        tournamentName: widget.tournament.name,
      ),
    );
  }
}


class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.tier,
    required this.name,
    required this.recLv,
    required this.accent,
    required this.isDark,
    required this.onBack,
  });

  final int tier;
  final String name;
  final String recLv;
  final Color accent;
  final bool isDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final inkColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AnimatedTapButton(
            onTap: onBack,
            scaleDown: 0.88,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white24 : const Color(0x661A1A1A),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white60 : const Color(0xFF1A1A1A),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Text(
                        'TIER $tier',
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 10,
                          letterSpacing: 2.5,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      recLv,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: (isDark ? Colors.white : const Color(0xFF1A1A1A))
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 22,
                    letterSpacing: 3,
                    color: inkColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _StageBlock extends StatelessWidget {
  const _StageBlock({
    required this.stage,
    required this.progress,
    required this.isDark,
    required this.accent,
    required this.delayBase,
    required this.onFight,
  });

  final StageData stage;
  final Map<String, String> progress;
  final bool isDark;
  final Color accent;
  final int delayBase;
  final Future<void> Function(TSlot) onFight;

  @override
  Widget build(BuildContext context) {
    final stageUnlocked = isSlotUnlocked(stage.normalSlots.first, progress);
    final headerCol = stageUnlocked
        ? accent
        : (isDark ? Colors.white24 : const Color(0xFFCCCCCC));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: headerCol, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  stage.label,
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 10,
                    letterSpacing: 2.5,
                    color: headerCol,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: headerCol.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ),

        ...stage.normalSlots.asMap().entries.map((e) {
          final idx = e.key;
          final slot = e.value;
          return _LevelSlotCard(
            slot: slot,
            progress: progress,
            isDark: isDark,
            accent: accent,
            delay: delayBase + idx * 40,
            onFight: () => onFight(slot),
          )
              .animate(delay: Duration(milliseconds: delayBase + idx * 40))
              .fadeIn(duration: 280.ms)
              .slideX(begin: 0.04, end: 0);
        }),

        _LevelSlotCard(
          slot: stage.bossSlot,
          progress: progress,
          isDark: isDark,
          accent: accent,
          delay: delayBase + 120,
          isBossRow: true,
          onFight: () => onFight(stage.bossSlot),
        )
            .animate(delay: Duration(milliseconds: delayBase + 120))
            .fadeIn(duration: 280.ms)
            .slideX(begin: 0.04, end: 0),

        const SizedBox(height: 4),
      ],
    );
  }
}


class _LevelSlotCard extends StatelessWidget {
  const _LevelSlotCard({
    required this.slot,
    required this.progress,
    required this.isDark,
    required this.accent,
    required this.delay,
    required this.onFight,
    this.isBossRow = false,
  });

  final TSlot slot;
  final Map<String, String> progress;
  final bool isDark;
  final Color accent;
  final int delay;
  final VoidCallback onFight;
  final bool isBossRow;

  @override
  Widget build(BuildContext context) {
    final unlocked = isSlotUnlocked(slot, progress);
    final completed = progress.containsKey(slot.id);

    final Color cardBg;
    final Color borderCol;
    if (!unlocked) {
      cardBg = isDark ? const Color(0xFF1A1000) : const Color(0xFFEEEEEE);
      borderCol = isDark ? Colors.white12 : const Color(0xFFDDDDDD);
    } else if (completed) {
      cardBg = isDark ? const Color(0xFF0F1A06) : const Color(0xFFF0F7ED);
      borderCol = isDark
          ? const Color(0xFF2A6A10).withValues(alpha: 0.6)
          : const Color(0xFF4CAF50).withValues(alpha: 0.45);
    } else if (isBossRow) {
      cardBg = isDark ? const Color(0xFF1A0D00) : const Color(0xFFFFF9EE);
      borderCol = isDark
          ? accent.withValues(alpha: 0.55)
          : const Color(0xFFAA8800).withValues(alpha: 0.6);
    } else {
      cardBg = isDark ? const Color(0xFF140A00) : const Color(0xFFFDFDFB);
      borderCol = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFF1A1A1A).withValues(alpha: 0.18);
    }

    final nameColor = !unlocked
        ? (isDark ? Colors.white24 : const Color(0xFFAAAAAA))
        : completed
            ? (isDark ? const Color(0xFF6EC858) : const Color(0xFF4CAF50))
            : (isDark
                ? Colors.white.withValues(alpha: 0.85)
                : const Color(0xFF1A1A1A));

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderCol, width: isBossRow ? 1.8 : 1.2),
          boxShadow: completed || !unlocked
              ? null
              : [
                  BoxShadow(
                    color: borderCol.withValues(alpha: 0.25),
                    blurRadius: 0,
                    offset: const Offset(2, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _SlotIcon(
                unlocked: unlocked,
                completed: completed,
                isBoss: isBossRow,
                isDark: isDark,
                accent: accent,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBossRow)
                      Text(
                        slot.isExtreme ? 'EXTREME BOSS' : 'BOSS',
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 9,
                          letterSpacing: 2.5,
                          color: unlocked
                              ? accent.withValues(alpha: 0.8)
                              : (isDark
                                  ? Colors.white24
                                  : const Color(0xFFCCCCCC)),
                        ),
                      ),
                    Text(
                      slot.enemyName,
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: isBossRow ? 16 : 14,
                        letterSpacing: 1.5,
                        color: nameColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (!unlocked)
                const Icon(Icons.lock_outline,
                    color: Color(0xFFAAAAAA), size: 18)
              else
                _FightButton(
                  label: completed ? 'REPLAY' : 'FIGHT',
                  isDark: isDark,
                  accent: accent,
                  replayed: completed,
                  onTap: onFight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotIcon extends StatelessWidget {
  const _SlotIcon({
    required this.unlocked,
    required this.completed,
    required this.isBoss,
    required this.isDark,
    required this.accent,
  });

  final bool unlocked;
  final bool completed;
  final bool isBoss;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return Icon(Icons.lock_outline,
          size: 20, color: isDark ? Colors.white24 : const Color(0xFFCCCCCC));
    }
    if (completed) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Color(0xFF4CAF50)),
      );
    }
    if (isBoss) {
      return Icon(Icons.whatshot, size: 22, color: accent);
    }
    return Icon(
      Icons.person_outline,
      size: 20,
      color: isDark
          ? Colors.white.withValues(alpha: 0.4)
          : const Color(0xFF1A1A1A).withValues(alpha: 0.4),
    );
  }
}

class _FightButton extends StatelessWidget {
  const _FightButton({
    required this.label,
    required this.isDark,
    required this.accent,
    required this.replayed,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final Color accent;
  final bool replayed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = replayed
        ? (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFEEEEEE))
        : accent;
    final textCol = replayed
        ? (isDark ? Colors.white54 : const Color(0xFF555555))
        : Colors.white;
    final borderCol = replayed
        ? (isDark ? Colors.white12 : const Color(0xFFCCCCCC))
        : const Color(0xFF1A1A1A).withValues(alpha: 0.4);

    return AnimatedTapButton(
      onTap: onTap,
      scaleDown: 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderCol, width: 1.2),
          boxShadow: replayed
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 12,
            letterSpacing: 2,
            color: textCol,
          ),
        ),
      ),
    );
  }
}


class _ChestFab extends StatefulWidget {
  const _ChestFab({
    required this.claimableCount,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  final int claimableCount;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ChestFab> createState() => _ChestFabState();
}

class _ChestFabState extends State<_ChestFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.claimableCount > 0) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ChestFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.claimableCount > 0 && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.claimableCount == 0 && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasClaimable = widget.claimableCount > 0;
    final bg = hasClaimable
        ? AppColors.ink
        : (widget.isDark ? AppColors.charcoal : AppColors.paperWhite);
    final border = hasClaimable
        ? AppColors.ink
        : (widget.isDark ? Colors.white24 : AppColors.lightGray);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final scale = hasClaimable ? 1.0 + _pulse.value * 0.07 : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedTapButton(
        onTap: widget.onTap,
        scaleDown: 0.90,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 2),
            boxShadow: [
              BoxShadow(
                color: (hasClaimable ? AppColors.shadow : Colors.black)
                    .withValues(alpha: hasClaimable ? 0.4 : 0.2),
                blurRadius: hasClaimable ? 12 : 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: hasClaimable
                    ? AppColors.pureWhite
                    : (widget.isDark
                        ? Colors.white60
                        : AppColors.sketchGray),
                size: 26,
              ),
              if (widget.claimableCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.darkGray,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.claimableCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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


class _LightPaperTexture extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PaperPainter());
  }
}

class _DarkInkTexture extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.2,
          colors: [Color(0xFF1A0D00), Color(0xFF0D0600)],
        ),
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  static final _rng = math.Random(77);
  static final _lines = List.generate(
    40,
    (_) => _rng.nextDouble(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white);
    final p = Paint()
      ..color = const Color(0xFFB8D4F0).withValues(alpha: 0.30)
      ..strokeWidth = 0.7;
    for (final f in _lines) {
      final y = f * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    canvas.drawLine(
      const Offset(28, 0),
      Offset(28, size.height),
      Paint()
        ..color = const Color(0xFFFFB3BA).withValues(alpha: 0.30)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperPainter old) => false;
}
