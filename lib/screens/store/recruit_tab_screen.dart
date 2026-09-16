import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/character_viewer/character_model_registry.dart';
import 'package:colosynth/character_viewer/character_model_viewer.dart';
import 'package:colosynth/game_data/character_database.dart';
import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/store/recruit_confirm_overlay.dart';

class RecruitTabScreen extends ConsumerStatefulWidget {
  const RecruitTabScreen({super.key});

  @override
  ConsumerState<RecruitTabScreen> createState() => _RecruitTabScreenState();
}

class _RecruitTabScreenState extends ConsumerState<RecruitTabScreen> {
  int _selectedIndex = 0;
  final List<CharacterData> _characters = CharacterDatabase.all;

  void _selectCharacter(int index) {
    final normIdx = (index % _characters.length + _characters.length) % _characters.length;
    if (normIdx == _selectedIndex) return;

    AudioService.instance.playSfx(SfxEvent.navigate);
    setState(() {
      _selectedIndex = normIdx;
    });
  }

  void _nextCharacter() {
    ComicButton.playButtonSfx();
    _selectCharacter(_selectedIndex + 1);
  }

  void _previousCharacter() {
    ComicButton.playButtonSfx();
    _selectCharacter(_selectedIndex - 1);
  }

  void _onRecruitTap(CharacterData character, bool isOwned, int playerPaint) {
    if (isOwned) return;

    RecruitConfirmOverlay.show(
      context,
      character: character,
      canAfford: playerPaint >= character.paintCost,
      onConfirm: () => _handleRecruit(character),
    );
  }

  Future<void> _handleRecruit(CharacterData character) async {
    try {
      await ref
          .read(walletProvider.notifier)
          .spend(Currency.paint, character.paintCost, reason: 'recruit');
      await ref
          .read(unlockedCharactersProvider.notifier)
          .unlock(character.id);

      if (!mounted) return;
      unawaited(LockedFeatureOverlay.show(
        context,
        customTitle: 'Recruit Success',
        customDescription:
            'Congratulations! ${character.name} is now part of your roster.',
        customConditionText: 'Recruited!',
        customEmoji: '🎉',
      ));
    } catch (e) {
      if (mounted) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Recruit Failed',
          customDescription: 'Recruitment could not be completed.',
          customConditionText: 'Error',
          customEmoji: '❌',
        ));
      }
    }
  }

  Color _rarityColor(CharacterRarity rarity) {
    switch (rarity) {
      case CharacterRarity.legendary:
        return const Color(0xFFFFFFFF);
      case CharacterRarity.epic:
        return const Color(0xFFDDDDDD);
      case CharacterRarity.rare:
        return const Color(0xFFAAAAAA);
      case CharacterRarity.common:
        return const Color(0xFF777777);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paint = ref.watch(paintProvider);
    final unlocked = ref.watch(unlockedCharactersProvider);

    final character = _characters[_selectedIndex];
    final isOwned = unlocked.contains(character.id) || character.id == 'arthur';
    final canAfford = paint >= character.paintCost;
    final color = _rarityColor(character.rarity);

    return Column(
      children: [
        // Top Header
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          child: Column(
            key: ValueKey('header_${character.id}'),
            children: [
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  character.rarity.name.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontFamily: 'Bangers',
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                character.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Bangers',
                  fontSize: 26,
                  letterSpacing: 3,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '${character.role.toUpperCase()} • ${character.description}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Surround Card Carousel (Amphitheater 3D perspective)
        Expanded(
          child: _SurroundCardCarousel(
            characters: _characters,
            selectedIndex: _selectedIndex,
            unlockedIds: unlocked,
            onSelectCharacter: _selectCharacter,
            onPrevious: _previousCharacter,
            onNext: _nextCharacter,
            rarityColor: _rarityColor,
          ),
        ),

        // Page Dot Indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_characters.length, (i) {
              final isSel = i == _selectedIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSel ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF00E5FF) : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),

        // Bottom Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: isOwned
              ? Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white70,
                      width: 1.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'RECRUITED / OWNED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Bangers',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: canAfford ? Colors.white70 : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.brush_rounded,
                            color: canAfford ? Colors.white : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${character.paintCost}',
                            style: TextStyle(
                              color: canAfford
                                  ? Colors.white
                                  : Colors.white38,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onRecruitTap(character, isOwned, paint),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: canAfford
                                ? Colors.white
                                : const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1A1A1A),
                              width: 1.5,
                            ),
                            boxShadow: canAfford
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            canAfford ? 'RECRUIT CHARACTER' : 'NEED MORE PAINT',
                            style: TextStyle(
                              color: canAfford ? const Color(0xFF1A1A1A) : Colors.white38,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Bangers',
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _SurroundCardCarousel extends StatefulWidget {
  const _SurroundCardCarousel({
    required this.characters,
    required this.selectedIndex,
    required this.unlockedIds,
    required this.onSelectCharacter,
    required this.onPrevious,
    required this.onNext,
    required this.rarityColor,
  });

  final List<CharacterData> characters;
  final int selectedIndex;
  final List<String> unlockedIds;
  final ValueChanged<int> onSelectCharacter;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Color Function(CharacterRarity) rarityColor;

  @override
  State<_SurroundCardCarousel> createState() => _SurroundCardCarouselState();
}

class _SurroundCardCarouselState extends State<_SurroundCardCarousel>
    with SingleTickerProviderStateMixin {
  late double _scroll;
  late final AnimationController _snapCtrl;
  Animation<double>? _snapAnim;
  double _snapFrom = 0;
  double _snapTo = 0;

  @override
  void initState() {
    super.initState();
    _scroll = widget.selectedIndex.toDouble();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )
      ..addListener(() {
        if (_snapAnim != null) {
          setState(() {
            _scroll = _snapAnim!.value;
          });
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          final total = widget.characters.length;
          if (total > 0) {
            final normalized = (_scroll % total + total) % total;
            setState(() {
              _scroll = normalized;
            });
            final normIdx = (normalized.round() % total + total) % total;
            if (normIdx != widget.selectedIndex) {
              widget.onSelectCharacter(normIdx);
            }
          }
        }
      });
  }

  @override
  void didUpdateWidget(covariant _SurroundCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final total = widget.characters.length;
      if (total > 0) {
        final currentNorm = (_scroll.round() % total + total) % total;
        if (currentNorm != widget.selectedIndex || !_snapCtrl.isAnimating) {
          _animateTo(widget.selectedIndex.toDouble());
        }
      }
    }
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _animateTo(double targetIndex) {
    final total = widget.characters.length;
    if (total == 0) return;

    final normScroll = (_scroll % total + total) % total;
    double delta = targetIndex - normScroll;
    while (delta < -total / 2.0) {
      delta += total;
    }
    while (delta > total / 2.0) {
      delta -= total;
    }

    _snapFrom = _scroll;
    _snapTo = _scroll + delta;
    _snapAnim = Tween<double>(begin: _snapFrom, end: _snapTo).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
    );
    _snapCtrl.forward(from: 0.0);
  }

  double _loopingDelta(int index, double scroll, int total) {
    double raw = index.toDouble() - scroll;
    while (raw < -total / 2.0) {
      raw += total;
    }
    while (raw > total / 2.0) {
      raw -= total;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.characters.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final W = constraints.maxWidth;
        final H = constraints.maxHeight;
        final centerX = W / 2;
        final centerY = H / 2;

        final cardWidth = math.min(W * 0.52, 210.0);
        final cardHeight = math.min(H * 0.90, 310.0);
        final stepX = cardWidth * 0.58;

        final cardEntries = <_SurroundCardEntry>[];
        for (int i = 0; i < total; i++) {
          final delta = _loopingDelta(i, _scroll, total);
          if (delta.abs() > 2.6) continue;
          cardEntries.add(_SurroundCardEntry(index: i, delta: delta));
        }

        // Sort by absolute delta descending: outer cards rendered first, center card rendered last on top
        cardEntries.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) {
            _snapCtrl.stop();
            final deltaScroll = -d.delta.dx / stepX;
            setState(() {
              _scroll = _scroll + deltaScroll;
            });
          },
          onPanEnd: (d) {
            final vx = -d.velocity.pixelsPerSecond.dx / stepX;
            final predicted = _scroll + vx * 0.22;
            if (total > 0) {
              final normPredicted = (predicted % total + total) % total;
              final target = normPredicted.round().toDouble();
              _animateTo(target);
              final targetIdx = (target.round() % total + total) % total;
              if (targetIdx != widget.selectedIndex) {
                widget.onSelectCharacter(targetIdx);
              }
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ...cardEntries.map((e) {
                final c = widget.characters[e.index];
                final isOwned = widget.unlockedIds.contains(c.id) || c.id == 'arthur';
                final cx = centerX + e.delta * stepX;
                final cy = centerY;

                return Positioned(
                  key: ValueKey('surround_card_${c.id}'),
                  left: cx - cardWidth / 2,
                  top: cy - cardHeight / 2,
                  width: cardWidth,
                  height: cardHeight,
                  child: _SurroundCharacterCard(
                    character: c,
                    delta: e.delta,
                    isOwned: isOwned,
                    rarityColor: widget.rarityColor(c.rarity),
                    width: cardWidth,
                    height: cardHeight,
                    onTap: () {
                      if (e.index != widget.selectedIndex) {
                        _animateTo(e.index.toDouble());
                        widget.onSelectCharacter(e.index);
                      }
                    },
                  ),
                );
              }),

              Positioned(
                left: 6,
                child: _ArrowButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: widget.onPrevious,
                ),
              ),

              Positioned(
                right: 6,
                child: _ArrowButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: widget.onNext,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SurroundCardEntry {
  const _SurroundCardEntry({required this.index, required this.delta});
  final int index;
  final double delta;
}

class _SurroundCharacterCard extends StatelessWidget {
  const _SurroundCharacterCard({
    required this.character,
    required this.delta,
    required this.isOwned,
    required this.rarityColor,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final CharacterData character;
  final double delta;
  final bool isOwned;
  final Color rarityColor;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final absD = delta.abs();
    final isCenter = absD < 0.45;
    final has3dModel = CharacterModelRegistry.hasModel(character.id);

    // 3D perspective transformation:
    // delta > 0 => card to the right => right edge LENGTHENS!
    // delta < 0 => card to the left  => left edge LENGTHENS!
    // delta = 0 => center card       => flat normal rectangle!
    final angle = (delta * 0.28).clamp(-0.62, 0.62);
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0014) // perspective
      ..rotateY(angle);

    final depthScale = (1.0 - absD * 0.04).clamp(0.85, 1.0);
    final opacity = (1.0 - (absD - 1.2).clamp(0.0, 1.5) * 0.35).clamp(0.40, 1.0);
    final dimAlpha = (absD * 0.24).clamp(0.0, 0.55);

    return Opacity(
      opacity: opacity,
      child: Transform(
        transform: transform,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: depthScale,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF141416),
                border: Border.all(
                  color: isCenter
                      ? const Color(0xFF00E5FF)
                      : rarityColor.withValues(alpha: 0.55),
                  width: isCenter ? 2.5 : 1.8,
                ),
                boxShadow: [
                  if (isCenter)
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.50),
                      blurRadius: 18,
                      spreadRadius: 2,
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ambient radial gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [
                            character.accentColor.withValues(alpha: isCenter ? 0.22 : 0.12),
                            const Color(0xFF0F0F12),
                          ],
                        ),
                      ),
                    ),

                    // Card Header Bar inside the card
                    Positioned(
                      top: 8,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: rarityColor.withValues(alpha: 0.8),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              character.rarity.name.toUpperCase(),
                              style: TextStyle(
                                color: rarityColor,
                                fontFamily: 'Bangers',
                                fontSize: 9,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                character.icon,
                                size: 12,
                                color: character.accentColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                character.role.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontFamily: 'Bangers',
                                  fontSize: 9,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Center visual: 3D model for focused center card, portrait for side cards
                    Positioned.fill(
                      top: 28,
                      bottom: 44,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: (isCenter && has3dModel)
                            ? IgnorePointer(
                                ignoring: true,
                                child: CharacterModelViewer(
                                  characterId: character.id,
                                  isLocked: !isOwned,
                                  autoRotate: true,
                                  allowUserControl: false,
                                  showActionBar: false,
                                  height: height * 0.62,
                                ),
                              )
                            : (character.thumbnailAsset != null
                                ? Image.asset(
                                    character.thumbnailAsset!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(
                                        character.icon,
                                        size: 56,
                                        color: character.accentColor,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      character.icon,
                                      size: 56,
                                      color: character.accentColor,
                                    ),
                                  )),
                      ),
                    ),

                    // Bottom info vignette & text
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                character.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Bangers',
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            if (isOwned)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 10, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text(
                                      'OWNED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Bangers',
                                        fontSize: 9,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Ambient dimming overlay for side cards to make center card pop
                    if (dimAlpha > 0.01)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: dimAlpha),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
