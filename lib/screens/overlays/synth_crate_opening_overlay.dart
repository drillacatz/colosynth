import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/growth/synth/synth_database.dart';
import 'package:colosynth/providers/synth_provider.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/game/logic/direction.dart';

enum SynthRarity {
  common('COMMON', Color(0xFFFFFFFF), Color(0xFFE0E0E0)),
  rare('RARE', Color(0xFF2196F3), Color(0xFF1976D2)),
  epic('EPIC', Color(0xFFAB47BC), Color(0xFF7B1FA2)),
  legendary('LEGENDARY', Color(0xFFFFD54F), Color(0xFFFFA000));

  final String label;
  final Color color;
  final Color shadowColor;

  const SynthRarity(this.label, this.color, this.shadowColor);

  static SynthRarity fromDefinitionId(String id) {
    final num = int.tryParse(id.replaceAll('synth_', '')) ?? 1;
    if (num >= 39) return SynthRarity.legendary;
    if (num >= 26) return SynthRarity.epic;
    if (num >= 13) return SynthRarity.rare;
    return SynthRarity.common;
  }
}

class SynthCrateOpeningOverlay extends ConsumerStatefulWidget {
  const SynthCrateOpeningOverlay({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onCompleted,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        fullscreenDialog: true,
        pageBuilder: (ctx, anim, secondaryAnim) => SynthCrateOpeningOverlay(
          onCompleted: onCompleted,
        ),
        transitionsBuilder: (ctx, anim, secondaryAnim, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  ConsumerState<SynthCrateOpeningOverlay> createState() =>
      _SynthCrateOpeningOverlayState();
}

class _SynthCrateOpeningOverlayState
    extends ConsumerState<SynthCrateOpeningOverlay>
    with TickerProviderStateMixin {
  int _chancesLeft = 4;
  int _tapsDone = 0;
  SynthRarity _currentRarity = SynthRarity.common;
  bool _isOpening = false;
  bool _isOpened = false;

  late final AnimationController _shakeController;
  late final AnimationController _particleController;

  final List<_WoodParticle> _particles = [];
  final math.Random _rng = math.Random();

  SynthDefinition? _awardedDefinition;
  bool _isDuplicate = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(_updateParticles);

    _prepareCrateReward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _prepareCrateReward() async {
    final result =
        await ref.read(ownedSynthInstancesProvider.notifier).openCrate();
    if (result != null) {
      _isDuplicate = result.isDuplicate;
      final defs = SynthDatabase.getAllDefinitions();
      _awardedDefinition = defs.firstWhere(
        (d) => d.id == result.instance.definitionId,
        orElse: () => defs.first,
      );
    } else {
      final defs = SynthDatabase.getAllDefinitions();
      _awardedDefinition = defs[_rng.nextInt(defs.length)];
    }
  }

  void _onChestTap() {
    if (_isOpened || _isOpening || _chancesLeft <= 0) return;

    HapticFeedback.heavyImpact();
    AudioService.instance.playSfx(
      _tapsDone == 3 ? SfxEvent.victory : SfxEvent.hit,
    );

    setState(() {
      _tapsDone++;
      _chancesLeft--;

      if (_tapsDone == 1) {
        if (_rng.nextDouble() < 0.70) _currentRarity = SynthRarity.rare;
      } else if (_tapsDone == 2) {
        if (_rng.nextDouble() < 0.55) _currentRarity = SynthRarity.epic;
      } else if (_tapsDone == 3) {
        if (_rng.nextDouble() < 0.40) _currentRarity = SynthRarity.legendary;
      } else if (_tapsDone >= 4) {
        if (_awardedDefinition != null) {
          _currentRarity =
              SynthRarity.fromDefinitionId(_awardedDefinition!.id);
        } else {
          _currentRarity = SynthRarity.legendary;
        }
      }
    });

    _spawnWoodParticles();
    _shakeController.forward(from: 0.0);

    if (_chancesLeft <= 0) {
      _burstOpenChest();
    }
  }

  void _spawnWoodParticles() {
    _particles.clear();
    const particleCount = 28;
    for (int i = 0; i < particleCount; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 120 + _rng.nextDouble() * 240;
      _particles.add(
        _WoodParticle(
          x: 0,
          y: 0,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 80,
          rotation: _rng.nextDouble() * 2 * math.pi,
          vRot: (_rng.nextDouble() - 0.5) * 12,
          size: 6 + _rng.nextDouble() * 12,
          color: i % 3 == 0
              ? const Color(0xFF8D6E63)
              : (i % 3 == 1
                  ? const Color(0xFF5D4037)
                  : _currentRarity.color),
        ),
      );
    }
    _particleController.forward(from: 0.0);
  }

  void _updateParticles() {
    final dt = 0.016;
    setState(() {
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 450 * dt;
        p.rotation += p.vRot * dt;
      }
    });
  }

  void _burstOpenChest() {
    setState(() {
      _isOpening = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      AudioService.instance.playSfx(SfxEvent.reward);
      setState(() {
        _isOpening = false;
        _isOpened = true;
      });
    });
  }

  void _onClose() {
    AudioService.instance.playSfx(SfxEvent.button);
    Navigator.of(context).pop();
    widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = 1.0 + (_tapsDone * 0.08);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xF7090910),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      _currentRarity.color.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isOpened)
            Positioned.fill(
              child: Center(
                child: _SunburstPainterWidget(color: _currentRarity.color)
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 12.seconds),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),

                const Spacer(),

                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_particleController.isAnimating)
                        CustomPaint(
                          painter: _WoodParticlePainter(
                            particles: _particles,
                            progress: _particleController.value,
                          ),
                        ),

                      if (!_isOpened)
                        GestureDetector(
                          onTap: _onChestTap,
                          child: AnimatedBuilder(
                            animation: _shakeController,
                            builder: (ctx, child) {
                              final shake = math.sin(
                                      _shakeController.value * math.pi * 6) *
                                  8.0 *
                                  (1.0 - _shakeController.value);
                              return Transform.translate(
                                offset: Offset(shake, 0),
                                child: Transform.scale(
                                  scale: scaleFactor,
                                  child: child,
                                ),
                              );
                            },
                            child: _ChestBoxGraphic(
                              tapsDone: _tapsDone,
                              rarity: _currentRarity,
                              isOpening: _isOpening,
                            ),
                          ),
                        )
                      else
                        _buildRevealedSynthCard(),
                    ],
                  ),
                ),

                const Spacer(),

                if (!_isOpened) _buildChancesIndicator(),

                if (_isOpened) _buildClaimButton(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: _currentRarity.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _currentRarity.color, width: 2),
          ),
          child: Text(
            _isOpened
                ? '${_currentRarity.label} SYNTH UNLOCKED!'
                : 'SYNTH CRATE',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 26,
              letterSpacing: 3,
              color: _currentRarity.color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isOpened
              ? 'NEW ABILITY ADDED TO INVENTORY'
              : 'TAP THE CHEST TO UPGRADE RARITY & OPEN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildChancesIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isAvailable = index < _chancesLeft;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAvailable
                    ? _currentRarity.color
                    : Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: isAvailable ? Colors.white : Colors.white24,
                  width: 2,
                ),
                boxShadow: isAvailable
                    ? [
                        BoxShadow(
                          color: _currentRarity.color.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          '$_chancesLeft CHANCES REMAINING',
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 14,
            letterSpacing: 2,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedSynthCard() {
    final def = _awardedDefinition;
    if (def == null) return const SizedBox.shrink();

    return Container(
      width: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161522),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _currentRarity.color, width: 3),
        boxShadow: [
          BoxShadow(
            color: _currentRarity.color.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _currentRarity.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentRarity.label,
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 14,
                color: Colors.black,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentRarity.color.withValues(alpha: 0.15),
              border: Border.all(color: _currentRarity.color, width: 2.5),
            ),
            child: Center(
              child: Icon(
                Icons.bolt,
                size: 54,
                color: _currentRarity.color,
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(),

          const SizedBox(height: 14),

          Text(
            def.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 24,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),

          if (_isDuplicate) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.comicYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.comicYellow, width: 1),
              ),
              child: const Text(
                'DUPLICATE: CONVERTED TO EXP NOTE',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 10,
                  color: AppColors.comicYellow,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: def.effectiveSequence.map((dir) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  _dirArrow(dir),
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatTile('DMG MULT', 'x${def.bonusDamageMult.toStringAsFixed(1)}'),
              _buildStatTile('STAM DMG', '+${def.counterStaminaDamage}'),
              _buildStatTile('CHARGE', '+${def.activeSkillChargeBonus}%'),
            ],
          ),
        ],
      ),
    );
  }

  String _dirArrow(AttackDirection dir) {
    switch (dir) {
      case AttackDirection.n:
        return '⬆️';
      case AttackDirection.s:
        return '⬇️';
      case AttackDirection.e:
        return '➡️';
      case AttackDirection.w:
        return '⬅️';
      case AttackDirection.ne:
        return '↗️';
      case AttackDirection.nw:
        return '↖️';
      case AttackDirection.se:
        return '↘️';
      case AttackDirection.sw:
        return '↙️';
    }
  }

  Widget _buildStatTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 18,
            color: _currentRarity.color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white38,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildClaimButton() {
    return GestureDetector(
      onTap: _onClose,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
        decoration: BoxDecoration(
          color: _currentRarity.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 4),
            ),
          ],
        ),
        child: const Text(
          'CLAIM SYNTH',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 20,
            letterSpacing: 3,
            color: Colors.black,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }
}


class _ChestBoxGraphic extends StatelessWidget {
  const _ChestBoxGraphic({
    required this.tapsDone,
    required this.rarity,
    required this.isOpening,
  });

  final int tapsDone;
  final SynthRarity rarity;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF4E342E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarity.color, width: 4),
        boxShadow: [
          BoxShadow(
            color: rarity.color.withValues(alpha: 0.5),
            blurRadius: 20 + (tapsDone * 8.0),
            spreadRadius: 2 + (tapsDone * 2.0),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ChestPainter(
          tapsDone: tapsDone,
          rarityColor: rarity.color,
          isOpening: isOpening,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 48,
                color: rarity.color,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TAP TO BREAK',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 14,
                    color: rarity.color,
                    letterSpacing: 1.5,
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

class _ChestPainter extends CustomPainter {
  final int tapsDone;
  final Color rarityColor;
  final bool isOpening;

  _ChestPainter({
    required this.tapsDone,
    required this.rarityColor,
    required this.isOpening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.33), Offset(size.width, size.height * 0.33), paint);
    canvas.drawLine(Offset(0, size.height * 0.66), Offset(size.width, size.height * 0.66), paint);

    final bandPaint = Paint()
      ..color = rarityColor.withValues(alpha: 0.8)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), bandPaint);

    if (tapsDone > 0) {
      final crackPaint = Paint()
        ..color = rarityColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(size.width * 0.2, 8);
      path.lineTo(size.width * 0.35, size.height * 0.3);
      path.lineTo(size.width * 0.25, size.height * 0.5);

      if (tapsDone > 1) {
        path.moveTo(size.width * 0.8, 8);
        path.lineTo(size.width * 0.65, size.height * 0.4);
        path.lineTo(size.width * 0.75, size.height * 0.7);
      }

      if (tapsDone > 2) {
        path.moveTo(size.width * 0.5, size.height - 8);
        path.lineTo(size.width * 0.4, size.height * 0.6);
        path.lineTo(size.width * 0.6, size.height * 0.3);
      }

      canvas.drawPath(path, crackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChestPainter old) =>
      old.tapsDone != tapsDone || old.rarityColor != rarityColor;
}


class _WoodParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double vRot;
  double size;
  Color color;

  _WoodParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.vRot,
    required this.size,
    required this.color,
  });
}

class _WoodParticlePainter extends CustomPainter {
  final List<_WoodParticle> particles;
  final double progress;

  _WoodParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WoodParticlePainter old) => true;
}


class _SunburstPainterWidget extends StatelessWidget {
  final Color color;
  const _SunburstPainterWidget({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(400, 400),
      painter: _SunburstPainter(color: color),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final Color color;
  _SunburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    const rays = 16;
    final angleStep = (2 * math.pi) / rays;

    for (int i = 0; i < rays; i++) {
      final startAngle = i * angleStep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: size.width),
          startAngle,
          angleStep * 0.4,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter old) => old.color != color;
}
