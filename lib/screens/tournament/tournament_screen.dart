import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

import 'package:colosynth/game_data/level_data.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/tier_chest_provider.dart';
import 'package:colosynth/providers/tutorial_provider.dart';
import 'package:colosynth/screens/level/level_screen.dart';
import 'package:colosynth/screens/tournament/battle_flow.dart';
import 'package:colosynth/screens/tournament/tournament_card.dart';
import 'package:colosynth/screens/tournament/tournament_logic.dart';
import 'package:colosynth/screens/tutorial/tutorial_levels_screen.dart';
import 'package:colosynth/widgets/common/animated_tap_button.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/theme/tokens.dart';

const _kInk = Color(0xFF1A1A1A);

class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(tournamentProgressProvider);
    final tutorialDone = ref.watch(tutorialCompletedProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const Positioned.fill(child: NotebookBackground()),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 52),
                  _TournamentHeader(onBack: () {
                    AudioService.instance.playSfx(SfxEvent.button);
                    Navigator.of(context).pop();
                  }),
                  Expanded(
                    child: _TournamentLayout(
                      progress: progress,
                      tutorialDone: tutorialDone,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentHeader extends StatelessWidget {
  const _TournamentHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AnimatedTapButton(
            onTap: onBack,
            scaleDown: 0.88,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kInk.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child:
                  const Icon(Icons.arrow_back_ios_new, color: _kInk, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'TOURNAMENT',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 28,
              letterSpacing: 5,
              color: _kInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentLayout extends ConsumerStatefulWidget {
  const _TournamentLayout({required this.progress, required this.tutorialDone});
  final Map<String, String> progress;
  final bool tutorialDone;

  @override
  ConsumerState<_TournamentLayout> createState() => _TournamentLayoutState();
}

class _TournamentLayoutState extends ConsumerState<_TournamentLayout>
    with SingleTickerProviderStateMixin {
  late final List<TItem> _items;
  late final TSlot? _extreme;

  double _scroll = 0.0;
  double _halfStep = 100.0;

  late final AnimationController _snapCtrl;
  Animation<double> _snapAnim = const AlwaysStoppedAnimation(0.0);
  double _snapFrom = 0.0;
  double _snapTo = 0.0;

  @override
  void initState() {
    super.initState();
    _items = buildTournamentList();
    _extreme = findExtremeSlot();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addListener(_onSnapTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _findLatestTargetIndex();
      if (target > 0) {
        _triggerSnap(target.toDouble());
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TournamentLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tutorialDone != oldWidget.tutorialDone ||
        widget.progress != oldWidget.progress) {
      final oldTarget = _findTargetFor(oldWidget.progress, oldWidget.tutorialDone);
      final newTarget = _findLatestTargetIndex();
      if (newTarget != oldTarget && newTarget >= 0) {
        _triggerSnap(newTarget.toDouble());
      }
    }
  }

  int _findLatestTargetIndex() =>
      _findTargetFor(widget.progress, widget.tutorialDone);

  int _findTargetFor(Map<String, String> progress, bool tutorialDone) {
    if (!tutorialDone) return 0;

    int lastUnlocked = 0;
    for (int i = 0; i < _items.length; i++) {
      final dataIndex = i + 1;
      if (_unlockedWith(dataIndex, progress)) {
        lastUnlocked = dataIndex;
        final t = _items[i].tournament;
        final isCompleted =
            tournamentCompletedCount(t, progress) >=
                tournamentTotalSlots(t);
        if (!isCompleted) {
          return dataIndex;
        }
      }
    }

    if (_extreme != null && _unlockedWith(1 + _items.length, progress)) {
      return 1 + _items.length;
    }

    return lastUnlocked;
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onSnapTick() {
    if (mounted) setState(() => _scroll = _snapAnim.value);
  }

  int get _totalCount => 1 + _items.length + (_extreme != null ? 1 : 0);

  int get _selectedIndex =>
      _scroll.round().clamp(0, math.max(0, _totalCount - 1));

  bool get _isExtremeSelected =>
      _extreme != null && _selectedIndex == 1 + _items.length;

  bool get _isTutorialSelected => _selectedIndex == 0;

  bool _unlocked(int dataIndex) => _unlockedWith(dataIndex, widget.progress);

  bool _unlockedWith(int dataIndex, Map<String, String> progress) {
    if (dataIndex == 0) return true;
    if (_extreme != null && dataIndex == 1 + _items.length) {
      return isExtremeItemUnlocked(_extreme, progress);
    }
    final ti = dataIndex - 1;
    if (ti >= 0 && ti < _items.length) {
      return isTournamentItemUnlocked(_items[ti].tournament, progress);
    }
    return false;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _snapCtrl.stop();
    final delta = (d.delta.dx - d.delta.dy) / (2.0 * _halfStep);
    setState(() {
      _scroll = (_scroll + delta).clamp(0.0, (_totalCount - 1).toDouble());
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;
    final vy = d.velocity.pixelsPerSecond.dy;
    final cardVelocity = (vx - vy) / (2.0 * _halfStep);
    final predicted = _scroll + cardVelocity * 0.26;
    final target =
        predicted.round().toDouble().clamp(0.0, (_totalCount - 1).toDouble());
    _triggerSnap(target);
  }

  void _triggerSnap(double target) {
    _snapFrom = _scroll;
    _snapTo = target;
    _snapAnim = Tween<double>(begin: _snapFrom, end: _snapTo)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_snapCtrl);
    _snapCtrl.forward(from: 0.0);
  }

  void _onCardTap(int dataIndex) {
    if (dataIndex == _selectedIndex) {
      _onEnter();
    } else {
      AudioService.instance.playSfx(SfxEvent.navigate);
      _triggerSnap(
          dataIndex.toDouble().clamp(0.0, (_totalCount - 1).toDouble()));
    }
  }

  void _onEnter() {
    AudioService.instance.playSfx(SfxEvent.button);
    if (_isTutorialSelected) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const TutorialLevelsScreen(),
        ),
      );
      return;
    }
    if (_isExtremeSelected) {
      if (_extreme == null ||
          !isExtremeItemUnlocked(_extreme, widget.progress)) {
        return;
      }
      const flow = TournamentBattleFlow();
      flow.fight(context: context, ref: ref, slot: _extreme);
      return;
    }
    final ti = _selectedIndex - 1;
    if (ti < 0 || ti >= _items.length) return;
    final item = _items[ti];
    if (item.tournament.tier == 1 && !widget.tutorialDone) return;
    if (!isTournamentItemUnlocked(item.tournament, widget.progress)) return;
    LevelScreen.push(
      context,
      tournament: item.tournament,
      style: item.style,
    );
  }

  Widget? _cardWidget(int dataIndex) {
    if (dataIndex < 0 || dataIndex >= _totalCount) return null;
    final unlocked = _unlocked(dataIndex);
    if (dataIndex == 0) {
      return TutorialCard(
        done: widget.tutorialDone,
        onTap: () => _onCardTap(dataIndex),
      );
    }
    final extremeSlot = _extreme;
    if (extremeSlot != null && dataIndex == 1 + _items.length) {
      return ExtremeArenaCard(
        slot: extremeSlot,
        progress: widget.progress,
        unlocked: unlocked,
        onTap: () => _onCardTap(dataIndex),
      );
    }
    final ti = dataIndex - 1;
    if (ti >= 0 && ti < _items.length) {
      return ArenaCard(
        tournament: _items[ti].tournament,
        style: _items[ti].style,
        progress: widget.progress,
        unlocked: unlocked,
        onTap: () => _onCardTap(dataIndex),
      );
    }
    return null;
  }

  double _scaleFor(double d) {
    final a = d.abs();
    if (a <= 1.0) return lerpDouble(1.0, 0.50, a)!;
    if (a <= 2.0) return lerpDouble(0.50, 0.25, a - 1.0)!;
    return lerpDouble(0.25, 0.0, (a - 2.0).clamp(0.0, 1.0))!;
  }

  double _opacityFor(double d) {
    final a = d.abs();
    if (a <= 1.0) return lerpDouble(1.0, 0.78, a)!;
    if (a <= 2.0) return lerpDouble(0.78, 0.38, a - 1.0)!;
    return lerpDouble(0.38, 0.0, (a - 2.0).clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final W = constraints.maxWidth;
      final H = constraints.maxHeight;

      final mainSize = math.min(W * 0.40, H * 0.36) * 1.2;
      _halfStep = mainSize * 0.82;

      final anchorX = W * 0.68;
      final anchorY = H * 0.60;

      final firstIdx = (_scroll - 2.6)
          .floor()
          .clamp(0, math.max(0, _totalCount - 1))
          .toInt();
      final lastIdx =
          (_scroll + 2.6).ceil().clamp(0, math.max(0, _totalCount - 1)).toInt();

      final entries = <_CardEntry>[];
      for (var i = firstIdx; i <= lastIdx; i++) {
        final d = i.toDouble() - _scroll;
        if (d.abs() >= 2.85) continue;
        final card = _cardWidget(i);
        if (card == null) continue;
        entries.add(_CardEntry(index: i, delta: d, widget: card));
      }

      entries.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

      final cardWidgets = <Widget>[];
      for (final e in entries) {
        final scale = _scaleFor(e.delta);
        final opacity = _opacityFor(e.delta).clamp(0.0, 1.0);
        final sz = mainSize * scale;
        final cx = anchorX - e.delta * _halfStep;
        final cy = anchorY + e.delta * _halfStep;
        cardWidgets.add(
          Positioned(
            key: ValueKey(e.index),
            left: cx - sz / 2,
            top: cy - sz / 2,
            width: sz,
            height: sz,
            child: Opacity(
              opacity: opacity,
              child: e.widget,
            ),
          ),
        );
      }

      final selIdx = _selectedIndex;
      final isExtreme = _extreme != null && selIdx == 1 + _items.length;
      bool btnUnlocked;
      String btnLabel;
      Color btnAccent;
      if (selIdx == 0) {
        btnUnlocked = true;
        btnLabel = widget.tutorialDone ? 'REPLAY TUTORIAL' : 'START TUTORIAL';
        btnAccent = AppColors.ink;
      } else if (isExtreme) {
        btnUnlocked = isExtremeItemUnlocked(_extreme, widget.progress);
        final completed = widget.progress[_extreme.id] != null;
        btnLabel = completed ? 'CHALLENGE AGAIN' : 'CHALLENGE';
        btnAccent = AppColors.darkGray;
      } else {
        final ti = selIdx - 1;
        if (ti >= 0 && ti < _items.length) {
          final item = _items[ti];
          final isTutorialLocked =
              item.tournament.tier == 1 && !widget.tutorialDone;
          btnUnlocked = !isTutorialLocked &&
              isTournamentItemUnlocked(item.tournament, widget.progress);
          final done =
              tournamentCompletedCount(item.tournament, widget.progress) ==
                      tournamentTotalSlots(item.tournament) &&
                  tournamentTotalSlots(item.tournament) > 0;
          btnLabel =
              isTutorialLocked ? 'TUTORIAL FIRST' : (done ? 'REPLAY' : 'ENTER');
          btnAccent = item.tournament.accentColor;
        } else {
          btnUnlocked = false;
          btnLabel = 'ENTER';
          btnAccent = const Color(0xFF1A1A1A);
        }
      }

      final btnWidth = mainSize * 1.1;
      final btnTop = anchorY + mainSize * 0.55;

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: W * 0.56,
            height: H * 0.52,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              ),
              child: _DetailPane(
                key: ValueKey('$_selectedIndex-${widget.progress.length}-${widget.tutorialDone}'),
                items: _items,
                extreme: _extreme,
                selectedIndex: _selectedIndex,
                progress: widget.progress,
                tutorialDone: widget.tutorialDone,
                onEnter: _onEnter,
                tutorialIndex: 0,
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: cardWidgets,
              ),
            ),
          ),
          Positioned(
            left: anchorX - btnWidth / 2,
            top: btnTop,
            width: btnWidth,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              ),
              child: _EnterButton(
                key: ValueKey(_selectedIndex),
                unlocked: btnUnlocked,
                label: btnLabel,
                accent: btnAccent,
                onEnter: _onEnter,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _CardEntry {
  const _CardEntry({
    required this.index,
    required this.delta,
    required this.widget,
  });
  final int index;
  final double delta;
  final Widget widget;
}

class _DetailPane extends ConsumerWidget {
  const _DetailPane({
    super.key,
    required this.items,
    required this.extreme,
    required this.selectedIndex,
    required this.progress,
    required this.tutorialDone,
    required this.onEnter,
    this.tutorialIndex = 0,
  });

  final List<TItem> items;
  final TSlot? extreme;
  final int selectedIndex;
  final Map<String, String> progress;
  final bool tutorialDone;
  final VoidCallback onEnter;
  final int tutorialIndex;

  bool get _isExtremeSelected =>
      extreme != null && selectedIndex == 1 + items.length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedIndex == tutorialIndex) {
      return _TutorialPane(
        done: tutorialDone,
        onEnter: onEnter,
      );
    }
    if (_isExtremeSelected && extreme != null) {
      return _ExtremePane(
        slot: extreme!,
        unlocked: isExtremeItemUnlocked(extreme, progress),
        progress: progress,
        onEnter: onEnter,
      );
    }
    final ti = selectedIndex - 1;
    if (ti >= 0 && ti < items.length) {
      final item = items[ti];
      return _TournamentPane(
        item: item,
        progress: progress,
        unlocked: isTournamentItemUnlocked(item.tournament, progress),
        tutorialDone: tutorialDone,
        onEnter: onEnter,
      );
    }
    return const SizedBox.shrink();
  }
}

class _TutorialPane extends StatelessWidget {
  const _TutorialPane({required this.done, required this.onEnter});
  final bool done;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TUTORIAL',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 26,
              letterSpacing: 2,
              color: accent,
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(
                begin: 0.06,
                end: 0,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),
          if (done) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                    width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 12, color: Color(0xFF4CAF50)),
                  SizedBox(width: 5),
                  Text(
                    'TUTORIAL COMPLETED',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 10,
                      letterSpacing: 2,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 120.ms).fadeIn(duration: 300.ms),
          ] else ...[
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 13, color: accent),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Required to unlock Tier 1',
                    style: TextStyle(fontSize: 11, color: accent),
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 200.ms),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _TournamentPane extends ConsumerWidget {
  const _TournamentPane({
    required this.item,
    required this.progress,
    required this.unlocked,
    required this.tutorialDone,
    required this.onEnter,
  });

  final TItem item;
  final Map<String, String> progress;
  final bool unlocked;
  final bool tutorialDone;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = item.tournament;
    const inkColor = Color(0xFF1A1A1A);
    const subColor = Color(0xFF888888);

    final chestState = ref.watch(tierChestProvider(t.tier));
    final allChestClaimed = chestState.allClaimed;
    final isTutorialLocked = t.tier == 1 && !tutorialDone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.name,
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 26,
              letterSpacing: 4,
              color: inkColor,
            ),
          ).animate().fadeIn(duration: 220.ms, curve: Curves.easeOut).slideY(
                begin: 0.06,
                end: 0,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 4),
          Text(
            t.recLv,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              color: subColor,
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 200.ms),
          if (isTutorialLocked) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_outlined,
                    size: 13, color: Color(0xFF00E5FF)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Complete the tutorial to unlock',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 200.ms),
          ] else if (!unlocked) ...[
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 13, color: subColor),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Complete previous tier to unlock',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 200.ms),
          ],
          if (allChestClaimed) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                    width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 12, color: Color(0xFF4CAF50)),
                  SizedBox(width: 5),
                  Text(
                    'ALL REWARDS CLAIMED',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 10,
                      letterSpacing: 2,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 140.ms).fadeIn(duration: 300.ms),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _ExtremePane extends StatelessWidget {
  const _ExtremePane({
    required this.slot,
    required this.unlocked,
    required this.progress,
    required this.onEnter,
  });

  final TSlot slot;
  final bool unlocked;
  final Map<String, String> progress;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final completed = progress[slot.id] != null;
    const red = Color(0xFFFF4444);
    const subColor = Color(0xFF888888);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXTREME',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 11,
              letterSpacing: 4,
              color: red,
            ),
          ).animate().fadeIn(duration: 200.ms),
          const SizedBox(height: 2),
          Text(
            slot.enemyName,
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 26,
              letterSpacing: 4,
              color: Color(0xFF1A1A1A),
            ),
          ).animate(delay: 50.ms).fadeIn(duration: 220.ms).slideY(
                begin: 0.06,
                end: 0,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 4),
          if (!unlocked)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 13, color: subColor),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Complete all tiers to unlock',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 200.ms)
          else if (completed)
            const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 13, color: Color(0xFF4CAF50)),
                SizedBox(width: 4),
                Text(
                  'CONQUERED',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 200.ms),
          const Spacer(),
        ],
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  const _EnterButton({
    super.key,
    required this.unlocked,
    required this.label,
    required this.accent,
    required this.onEnter,
  });

  final bool unlocked;
  final String label;
  final Color accent;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFFEEEEEE),
          border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 13, color: Color(0xFFAAAAAA)),
              SizedBox(width: 6),
              Text(
                'LOCKED',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 14,
                  letterSpacing: 3,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedTapButton(
      onTap: onEnter,
      scaleDown: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: accent,
          border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331A1A1A),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 15,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
