import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/screens/theme/shared_painters.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/guide/guide_anchor.dart';


@immutable
class TabInfo {
  const TabInfo({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.feature,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final UnlockableFeature? feature;
}

class GameBottomBar extends StatefulWidget {
  const GameBottomBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.tabUnlocked,
    required this.onTap,
    this.showRedDots,
  });

  final int selectedIndex;
  final List<TabInfo> tabs;
  final List<bool> tabUnlocked;
  final ValueChanged<int> onTap;
  final List<bool>? showRedDots;

  @override
  State<GameBottomBar> createState() => _GameBottomBarState();
}

class _GameBottomBarState extends State<GameBottomBar>
    with TickerProviderStateMixin {
  late final List<AnimationController> _tapCtrls;
  late final List<Animation<double>> _scaleAnims;

  static const _tapSpring =
      SpringDescription(mass: 1.0, stiffness: 500.0, damping: 28.0);

  @override
  void initState() {
    super.initState();
    _tapCtrls = List.generate(
      widget.tabs.length,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 110)),
    );
    _scaleAnims = _tapCtrls
        .map((c) => Tween<double>(begin: 1.0, end: 0.78)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeIn)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _tapCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleTap(int i) {
    ComicButton.playButtonSfx();
    final ctrl = _tapCtrls[i];
    ctrl.forward().then((_) {
      if (mounted) {
        ctrl.animateWith(SpringSimulation(_tapSpring, 1.0, 0.0, -5.0));
      }
    });
    widget.onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFB),
        border: Border(top: BorderSide(color: Color(0xFFD8D8D8), width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(widget.tabs.length, (i) {
            final tab = widget.tabs[i];
            final isSelected = i == widget.selectedIndex;
            final isUnlocked = widget.tabUnlocked[i];
            final keyId = 'tab_${tab.label.toLowerCase()}';
            return Expanded(
              key: ValueKey(keyId),
              child: GuideAnchor(
                id: keyId,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleTap(i),
                  child: AnimatedBuilder(
                    animation: _scaleAnims[i],
                    builder: (_, child) => Transform.scale(
                        scale: _scaleAnims[i].value, child: child),

                    child: _TabItem(
                      tab: tab,
                      isSelected: isSelected,
                      isUnlocked: isUnlocked,
                      showRedDot: widget.showRedDots?[i] ?? false,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.isUnlocked,
    this.showRedDot = false,
  });

  final TabInfo tab;
  final bool isSelected;
  final bool isUnlocked;
  final bool showRedDot;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF111111);
    const inactiveColor = Color(0xFFAAAAAA);
    const lockedColor = Color(0xFFCCCCCC);
    final showSelected = isSelected && isUnlocked;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            if (showSelected)
              CustomPaint(
                painter: SketchyHighlightPainter(
                  color: activeColor,
                  strokeWidth: 1.2,
                  jitter: 0.8,
                ),
                child: Container(
                  width: 42,
                  height: 28,
                  alignment: Alignment.center,
                  child: Icon(tab.activeIcon, color: activeColor, size: 20),
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.0),
                child: Icon(tab.icon,
                    color: isUnlocked ? inactiveColor : lockedColor, size: 22),
              ),
            if (!isUnlocked && tab.feature != null)
              Positioned(
                top: -2,
                right: -6,
                child: _LockBadge(
                  requiredLevel:
                      ProgressionService.instance.requiredLevel(tab.feature!),
                ),
              ),
            if (showRedDot && isUnlocked)
              const Positioned(
                top: -2,
                right: -2,
                child: _PulsingRedDot(),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          tab.label,
          style: TextStyle(
            color: isUnlocked
                ? (showSelected ? activeColor : inactiveColor)
                : lockedColor,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: showSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.requiredLevel});
  final int requiredLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E00),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white60, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, color: Colors.white, size: 7),
          const SizedBox(width: 2),
          Text(
            '$requiredLevel',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontFamily: 'Bangers',
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _PulsingRedDot extends StatefulWidget {
  const _PulsingRedDot();

  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.6),
              blurRadius: 3,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
