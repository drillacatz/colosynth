import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class CharacterRouletteWheel extends StatefulWidget {
  const CharacterRouletteWheel({
    super.key,
    required this.characters,
    required this.unlockedIds,
    required this.initialIndex,
    required this.onSelected,
  });

  final List<CharacterData> characters;
  final Set<String> unlockedIds;
  final int initialIndex;
  final ValueChanged<int> onSelected;

  @override
  State<CharacterRouletteWheel> createState() => _CharacterRouletteWheelState();
}

class _CharacterRouletteWheelState extends State<CharacterRouletteWheel>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _slotNotifier;
  late final AnimationController _snapCtrl;
  Animation<double> _snapAnim = const AlwaysStoppedAnimation(0.0);
  double _snapFrom = 0.0;
  double _snapTo = 0.0;
  int? _lastReportedIndex;

  static const double _kRadius = 235.0;
  static const double _kDragPxPerSlot = 65.0;
  static const double _kBaseSize = 135.0;
  static const double _kFrontAngle = -math.pi;

  @override
  void initState() {
    super.initState();
    _slotNotifier = ValueNotifier(widget.initialIndex.toDouble());
    _lastReportedIndex = widget.initialIndex;
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(_onSnapTick);
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    _slotNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CharacterRouletteWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characters.length != widget.characters.length &&
        widget.characters.isNotEmpty) {
      final oldN = oldWidget.characters.length;
      if (oldN > 0) {
        final currentSelected = _slotNotifier.value.round() % oldN;
        _slotNotifier.value = currentSelected.toDouble();
        _snapAnim = AlwaysStoppedAnimation(_slotNotifier.value);
        _snapCtrl.stop();
      }
    }
  }

  void _onSnapTick() {
    _slotNotifier.value = _snapAnim.value;
  }

  int get _selectedIndex {
    final n = widget.characters.length;
    if (n == 0) return 0;
    return (_slotNotifier.value.round() % n);
  }

  void _notifySelection(int idx) {
    if (idx != _lastReportedIndex) {
      _lastReportedIndex = idx;
      widget.onSelected(idx);
    }
  }

  void _triggerSnap(double target) {
    _snapFrom = _slotNotifier.value;
    _snapTo = target;
    _snapAnim = Tween<double>(begin: _snapFrom, end: _snapTo)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_snapCtrl);
    _snapCtrl.forward(from: 0.0);

    if (widget.characters.isNotEmpty) {
      final idx = target.round() % widget.characters.length;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifySelection(idx);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _snapCtrl.stop();
    final delta = d.delta.dy / _kDragPxPerSlot;
    _slotNotifier.value = _slotNotifier.value + delta;
    if (widget.characters.isNotEmpty) {
      final idx = _selectedIndex;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifySelection(idx);
      });
    }
  }

  void _onPanEnd(DragEndDetails d) {
    final vy = d.velocity.pixelsPerSecond.dy;
    final cardVelocity = vy / (1.5 * _kDragPxPerSlot);
    
    final maxSlots = 6.0;
    double deltaSlots = cardVelocity * 0.75;
    if (deltaSlots.abs() > maxSlots) {
      deltaSlots = deltaSlots.sign * maxSlots;
    }
    
    final predicted = _slotNotifier.value + deltaSlots;
    final target = predicted.round().toDouble();
    _triggerSnap(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final n = widget.characters.length;
      if (n == 0) return const SizedBox.shrink();

      final double effectiveRadius =
          math.max(_kRadius, (n * _kBaseSize * 1.15) / (2 * math.pi));

      final cx = constraints.maxWidth + 125.0 + (effectiveRadius - _kRadius);
      final cy = (constraints.maxHeight * 0.40);
      final angleStep = n > 1 ? (2 * math.pi) / n : math.pi;

      return ValueListenableBuilder<double>(
        valueListenable: _slotNotifier,
        builder: (context, slotValue, child) {
          final entries = <_RouletteEntry>[];
          for (int i = 0; i < n; i++) {
            double relAngle = ((i - slotValue) * angleStep).remainder(2 * math.pi);
            if (relAngle > math.pi) {
              relAngle -= 2 * math.pi;
            } else if (relAngle < -math.pi) {
              relAngle += 2 * math.pi;
            }

            final drawAngle = relAngle + _kFrontAngle;
            final x = cx + effectiveRadius * math.cos(drawAngle);
            
            if (x - _kBaseSize / 2 > constraints.maxWidth + 120.0) {
              continue;
            }

            final y = cy + effectiveRadius * math.sin(drawAngle);
            final proximity = (1.0 - relAngle.abs() / math.pi).clamp(0.0, 1.0);
            final scale = 0.40 + 0.60 * proximity;
            final opacity = (0.18 + 0.82 * proximity).clamp(0.0, 1.0);
            final selectedIndex = (slotValue.round() % n);
            final isSelected = i == selectedIndex;
            final isUnlocked = widget.unlockedIds.contains(widget.characters[i].id);

            entries.add(_RouletteEntry(
              proximity: proximity,
              widget: Positioned(
                key: ValueKey(i),
                left: x - _kBaseSize / 2,
                top: y - _kBaseSize / 2,
                child: GestureDetector(
                  onTapUp: (details) {
                    final radius = _kBaseSize / 2;
                    final dx = details.localPosition.dx - radius;
                    final dy = details.localPosition.dy - radius;
                    if (dx * dx + dy * dy <= radius * radius) {
                      ComicButton.playButtonSfx();
                      if (n > 0) {
                        final currentInt = slotValue.round();
                        int diff = i - (currentInt % n);
                        if (diff > n / 2) diff -= n;
                        if (diff < -n / 2) diff += n;
                        _triggerSnap((currentInt + diff).toDouble());
                      }
                    }
                  },
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: WheelSlot(
                        character: widget.characters[i],
                        isSelected: isSelected,
                        isUnlocked: isUnlocked,
                        size: _kBaseSize,
                      ),
                    ),
                  ),
                ),
              ),
            ));
          }

          entries.sort((a, b) => a.proximity.compareTo(b.proximity));

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                ),
              ),
              ...entries.map((e) => e.widget),
            ],
          );
        },
      );
    });
  }
}

class _RouletteEntry {
  const _RouletteEntry({required this.proximity, required this.widget});
  final double proximity;
  final Widget widget;
}

class WheelSlot extends StatelessWidget {
  const WheelSlot({
    super.key,
    required this.character,
    required this.isSelected,
    required this.isUnlocked,
    required this.size,
  });

  final CharacterData character;
  final bool isSelected;
  final bool isUnlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? AppColors.ink
              : AppColors.ink.withValues(alpha: 0.12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? AppColors.ink.withValues(alpha: 0.05)
                : AppColors.paperWhite.withValues(alpha: 0.95),
            border: isSelected
                ? Border.all(
                    color: AppColors.ink.withValues(alpha: 0.20),
                    width: 1.0,
                  )
                : null,
          ),
          child: ClipOval(
            child: Stack(
              children: [
                ColorFiltered(
                  colorFilter: isUnlocked
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                  child: _slotArt(),
                ),
                if (!isUnlocked)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _slotArt() {
    if (character.thumbnailAsset != null) {
      return Image.asset(
        character.thumbnailAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsArt(),
      );
    }
    return _initialsArt();
  }

  Widget _initialsArt() {
    return Container(
      color: AppColors.sketchGray.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          character.name[0].toUpperCase(),
          style: TextStyle(
            color: AppColors.ink.withValues(alpha: 0.4),
            fontSize: size * 0.36,
            fontWeight: FontWeight.w900,
            fontFamily: 'Bangers',
          ),
        ),
      ),
    );
  }
}
