import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/shared_painters.dart';
import 'package:colosynth/screens/theme/shared_widgets.dart';

const _kGold = AppColors.comicYellow;
Color get _kCardBg => AppColors.paperWhite;
Color get _kInk => AppColors.ink;
Color get _kSub => AppColors.sketchGray;
const _kInkBlue = Color(0xFF2196F3);
const _kPaintPink = Color(0xFFE91E63);

class ClaimRewardOverlay extends StatefulWidget {
  const ClaimRewardOverlay({
    super.key,
    required this.inkReward,
    required this.paintReward,
    this.xpReward = 0,
    this.stars,
    this.bonusLabel,
    this.bonusInk = 0,
    this.bonusPaint = 0,
    this.expItems = const {},
    required this.onDismiss,
  });

  final int inkReward;
  final int paintReward;
  final int xpReward;
  final int? stars;
  final String? bonusLabel;
  final int bonusInk;
  final int bonusPaint;
  final Map<String, int> expItems;
  final VoidCallback onDismiss;

  static Future<void> show(
    BuildContext context, {
    required int inkReward,
    required int paintReward,
    int xpReward = 0,
    int? stars,
    String? bonusLabel,
    int bonusInk = 0,
    int bonusPaint = 0,
    Map<String, int> expItems = const {},
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      builder: (ctx) => ClaimRewardOverlay(
        inkReward: inkReward,
        paintReward: paintReward,
        xpReward: xpReward,
        stars: stars,
        bonusLabel: bonusLabel,
        bonusInk: bonusInk,
        bonusPaint: bonusPaint,
        expItems: expItems,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<ClaimRewardOverlay> createState() => _ClaimRewardOverlayState();
}

class _ClaimRewardOverlayState extends State<ClaimRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    AudioService.instance.playSfx(SfxEvent.reward);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _scale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        ),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: _RewardPanel(
              inkReward: widget.inkReward,
              paintReward: widget.paintReward,
              xpReward: widget.xpReward,
              stars: widget.stars,
              bonusLabel: widget.bonusLabel,
              bonusInk: widget.bonusInk,
              bonusPaint: widget.bonusPaint,
              expItems: widget.expItems,
              onContinue: widget.onDismiss,
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel({
    required this.inkReward,
    required this.paintReward,
    required this.xpReward,
    this.stars,
    this.bonusLabel,
    required this.bonusInk,
    required this.bonusPaint,
    required this.expItems,
    required this.onContinue,
  });

  final int inkReward;
  final int paintReward;
  final int xpReward;
  final int? stars;
  final String? bonusLabel;
  final int bonusInk;
  final int bonusPaint;
  final Map<String, int> expItems;
  final VoidCallback onContinue;

  bool get _hasTierBonus =>
      bonusLabel != null && (bonusInk > 0 || bonusPaint > 0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _kInk, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: _kInk.withValues(alpha: 0.40),
              blurRadius: 0,
              offset: const Offset(5, 5),
            ),
            BoxShadow(
              color: _kGold.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BurstTitle(text: 'CLAIMED!'),
            const SizedBox(height: 4),
            if (stars != null) ...[
              const SizedBox(height: 14),
              MiniStarRow(stars: stars!),
            ],
            const SizedBox(height: 20),
            if (inkReward > 0) ...[
              RewardRow(
                icon: Icons.water_drop,
                color: _kInkBlue,
                label: 'INK',
                value: inkReward,
              ),
              const SizedBox(height: 8),
            ],
            if (paintReward > 0) ...[
              RewardRow(
                icon: Icons.brush,
                color: _kPaintPink,
                label: 'PAINT',
                value: paintReward,
              ),
              const SizedBox(height: 8),
            ],
            if (xpReward > 0) ...[
              RewardRow(
                icon: Icons.star,
                color: AppColors.comicYellow,
                label: 'XP',
                value: xpReward,
              ),
              const SizedBox(height: 8),
            ],
            for (final entry in expItems.entries) ...[
              if (entry.value > 0) ...[
                _buildExpItemRow(entry.key, entry.value),
                const SizedBox(height: 8),
              ],
            ],
            if (_hasTierBonus) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFFE0D8D0)),
              const SizedBox(height: 10),
              Text(
                '+ $bonusLabel TIER BONUS',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 11,
                  letterSpacing: 3,
                  color: _kSub,
                ),
              ),
              if (bonusInk > 0) ...[
                const SizedBox(height: 8),
                RewardRow(
                  icon: Icons.water_drop,
                  color: _kInkBlue,
                  label: 'INK',
                  value: bonusInk,
                ),
              ],
              if (bonusPaint > 0) ...[
                const SizedBox(height: 8),
                RewardRow(
                  icon: Icons.brush,
                  color: _kPaintPink,
                  label: 'PAINT',
                  value: bonusPaint,
                ),
              ],
            ],
            const SizedBox(height: 28),
            ComicButton(
              label: 'CONTINUE',
              style: PBStyle.white,
              fontSize: 18,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 13),
              onTap: onContinue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpItemRow(String itemId, int count) {
    String label = 'ITEM';
    Color color = Colors.grey;
    IconData icon = Icons.card_giftcard;

    String rarityLabel = '';
    if (itemId.endsWith('_common')) {
      rarityLabel = ' (COMMON)';
    } else if (itemId.endsWith('_rare')) {
      rarityLabel = ' (RARE)';
    } else if (itemId.endsWith('_epic')) {
      rarityLabel = ' (EPIC)';
    } else if (itemId.endsWith('_legendary')) {
      rarityLabel = ' (MYTHIC)';
    }

    if (itemId.startsWith('exp_hammer')) {
      label = 'FORGE HAMMER$rarityLabel';
      color = const Color(0xFF607D8B);
      icon = Icons.gavel;
    } else if (itemId.startsWith('exp_note')) {
      label = 'EXP NOTE$rarityLabel';
      color = const Color(0xFF00E5FF);
      icon = Icons.note;
    } else if (itemId.startsWith('exp_book')) {
      label = 'EXP BOOK$rarityLabel';
      color = const Color(0xFFFF9800);
      icon = Icons.book;
    }

    return RewardRow(
      icon: icon,
      color: color,
      label: label,
      value: count,
    );
  }
}

class _BurstTitle extends StatelessWidget {
  const _BurstTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    const fontSize = 38.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(fontSize * text.length * 0.66, fontSize * 1.8),
          painter: const BurstPainter(color: _kGold),
        ),
        Text(
          text,
          style: TextStyle(
            color: _kInk,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            fontFamily: 'Bangers',
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }
}
