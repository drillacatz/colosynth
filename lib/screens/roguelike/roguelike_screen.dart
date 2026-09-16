import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/services/battle_stats_service.dart';
import 'package:colosynth/services/interstitial_ad_service.dart';
import 'package:colosynth/services/battle_ads_service.dart';
import 'package:colosynth/game/ai/ai_profiles.dart';
import 'package:colosynth/game/app_shell/battle_screen.dart' as bg;
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/game_data/character_database.dart';
import 'package:colosynth/screens/ready/zigzag_lightning.dart';

class RoguelikeScreen extends ConsumerStatefulWidget {
  const RoguelikeScreen({super.key});

  @override
  ConsumerState<RoguelikeScreen> createState() => _RoguelikeScreenState();
}

class _RoguelikeScreenState extends ConsumerState<RoguelikeScreen> {
  int _bestFloor = 0;
  int _selectedFloor = 1;
  bool _loading = true;


  List<_Anomaly> _anomalies = [];

  @override
  void initState() {
    super.initState();
    _loadProgression();
  }

  Future<void> _loadProgression() async {
    final best = SaveManager.instance.loadBestEndlessFloor();
    if (!mounted) return;
    setState(() {
      _bestFloor = best;
      _selectedFloor = best + 1;
      _loading = false;
      _generateAnomalies();
    });
  }

  void _generateAnomalies() {
    final pool = [
      const _Anomaly(
        title: 'COMIC BURST',
        description: 'Perfect parries deal +40% counter damage, but failed blocks drain more stamina.',
        icon: Icons.flash_on,
        color: Color(0xFF00E5FF),
      ),
      const _Anomaly(
        title: 'HEAVY INK',
        description: 'Both you and the opponent receive +25% max health.',
        icon: Icons.invert_colors,
        color: Color(0xFFE91E63),
      ),
      const _Anomaly(
        title: 'PARRY SPARKS',
        description: 'Successful parries stagger the enemy for 1 extra beat.',
        icon: Icons.bolt,
        color: Color(0xFF00E676),
      ),
      const _Anomaly(
        title: 'CHALLENGER\'S RAGE',
        description: 'Enemy deals 20% more damage, but yields double Ink on victory.',
        icon: Icons.whatshot,
        color: Color(0xFFFF3D00),
      ),
      const _Anomaly(
        title: 'STEEL GUARD',
        description: 'Stamina cost for blocking attacks is reduced by 30%.',
        icon: Icons.shield,
        color: Color(0xFF29B6F6),
      ),
      const _Anomaly(
        title: 'STAMINA SLOW',
        description: 'Stamina regeneration is 15% slower for both combatants.',
        icon: Icons.hourglass_bottom,
        color: Color(0xFFAB47BC),
      ),
    ];


    final seed = _selectedFloor;
    final r = math.Random(seed);
    final List<_Anomaly> chosen = [];
    final available = List<_Anomaly>.from(pool);

    for (int i = 0; i < 2; i++) {
      if (available.isEmpty) break;
      final idx = r.nextInt(available.length);
      chosen.add(available.removeAt(idx));
    }

    setState(() {
      _anomalies = chosen;
    });
  }

  void _incrementFloor() {
    if (_selectedFloor >= _bestFloor + 1) return;
    ComicButton.playButtonSfx();
    setState(() {
      _selectedFloor++;
      _generateAnomalies();
    });
  }

  void _decrementFloor() {
    if (_selectedFloor <= 1) return;
    ComicButton.playButtonSfx();
    setState(() {
      _selectedFloor--;
      _generateAnomalies();
    });
  }

  Future<void> _startBattle() async {
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());






    final int tier = (((_selectedFloor - 1) ~/ 2) + 1).clamp(1, 11);
    final aiProfile = AiProfile.forTier(tier);

    final params = bg.BattleGameParams(
      slotId: 'endless_floor_$_selectedFloor',
      aiProfile: aiProfile,
      tier: tier,
    );


    final rootNav = Navigator.of(context, rootNavigator: true);
    final transitionCompleter = Completer<void>();
    final overlayEntry = OverlayEntry(
      builder: (_) => ZigzagEnterOverlay(
        onFinished: () => transitionCompleter.complete(),
      ),
    );
    rootNav.overlay?.insert(overlayEntry);
    await transitionCompleter.future;


    await AudioService.instance.playBgm(BgmTrack.battle);
    overlayEntry.remove();

    try {
      final result = await rootNav.push<bg.BattleResult?>(
        PageRouteBuilder<bg.BattleResult?>(
          pageBuilder: (context, animation, secondaryAnimation) => bg.BattleScreen(
            params: params,
            tournamentStage: 'endless_floor_$_selectedFloor',
            tournamentTier: tier,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );

      if (!mounted || result == null || result.outcome == bg.BattleOutcome.quit) {
        await AudioService.instance.playBgm(BgmTrack.home);
        return;
      }


      await BattleStatsService.instance.recordBattle(result: result);
      unawaited(InterstitialAdService.instance.recordBattleAndMaybeShow());

      if (result.outcome == bg.BattleOutcome.victory) {
        await _handleVictory();
      } else {
        await _handleDefeat();
      }
    } catch (e) {
      debugPrint('Endless battle run error: $e');
      await AudioService.instance.playBgm(BgmTrack.home);
    }
  }

  Future<void> _handleVictory() async {
    final inkReward = 150 * _selectedFloor;
    final paintReward = 2 * _selectedFloor;
    final xpReward = 50 * _selectedFloor;



    try {
      await ref.read(walletProvider.notifier).awardMultiple(
        ink: inkReward,
        paint: paintReward,
        source: 'endless_floor_reward',
      );
    } catch (e) {
      debugPrint('Endless reward grant (ink/paint) failed: $e');
    }
    try {
      await ref.read(accountLevelProvider.notifier).addXp(xpReward);
    } catch (e) {
      debugPrint('Endless reward grant (xp) failed: $e');
    }

    final bool newBest = _selectedFloor > _bestFloor;
    if (newBest) {
      await SaveManager.instance.saveBestEndlessFloor(_selectedFloor);
    }

    if (!mounted) return;


    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EndlessResultOverlay(
        isVictory: true,
        floor: _selectedFloor,
        ink: inkReward,
        paint: paintReward,
        xp: xpReward,
        newBest: newBest,
        onClose: () {
          Navigator.pop(ctx);
        },
      ),
    );


    await _loadProgression();
    await AudioService.instance.playBgm(BgmTrack.home);
  }

  Future<void> _handleDefeat() async {
    if (!mounted) return;


    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EndlessResultOverlay(
        isVictory: false,
        floor: _selectedFloor,
        ink: 0,
        paint: 0,
        xp: 0,
        newBest: false,
        onClose: () {
          Navigator.pop(ctx);
        },
      ),
    );

    await AudioService.instance.playBgm(BgmTrack.home);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      );
    }

    const inkColor = Color(0xFF1A1A1A);
    const accentColor = AppColors.sketchGray;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: accentColor, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'BEST FLOOR RECORD',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'FLOOR $_bestFloor',
                    style: const TextStyle(
                      color: accentColor,
                      fontFamily: 'Bangers',
                      fontSize: 22,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 16),


            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: inkColor, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF1A1A1A),
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CHOOSE FLOOR',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FloorArrowButton(
                          icon: Icons.chevron_left,
                          onPressed: _selectedFloor > 1 ? _decrementFloor : null,
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '$_selectedFloor',
                          style: const TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 72,
                            letterSpacing: 3,
                            color: inkColor,
                          ),
                        ).animate(key: ValueKey(_selectedFloor))
                            .scale(begin: const Offset(0.8, 0.8), duration: 200.ms, curve: Curves.easeOutBack),
                        const SizedBox(width: 24),
                        _FloorArrowButton(
                          icon: Icons.chevron_right,
                          onPressed: _selectedFloor < _bestFloor + 1 ? _incrementFloor : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFloor > _bestFloor ? '🔥 PREVIOUSLY UNCONQUERED!' : '🏆 REPLAY MODE',
                      style: TextStyle(
                        color: _selectedFloor > _bestFloor ? const Color(0xFFFF5722) : const Color(0xFF4CAF50),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
            ),

            const SizedBox(height: 16),


            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: inkColor.withValues(alpha: 0.15), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.layers_outlined, color: inkColor, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'FLOOR ANOMALIES & MODIFIERS',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _anomalies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final anomaly = _anomalies[idx];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: anomaly.color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(anomaly.icon, color: anomaly.color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      anomaly.title,
                                      style: TextStyle(
                                        color: anomaly.color,
                                        fontFamily: 'Bangers',
                                        fontSize: 13,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      anomaly.description,
                                      style: const TextStyle(
                                        color: Color(0xFF555555),
                                        fontSize: 11,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
            ),

            const SizedBox(height: 16),


            const _SynthBadge().animate(delay: 280.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 20),


            GestureDetector(
              onTap: _startBattle,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: inkColor, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D000000),
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'ENTER THE ARENA',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 18,
                      letterSpacing: 4,
                      color: inkColor,
                    ),
                  ),
                ),
              ),
            ).animate(delay: 350.ms).fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), duration: 250.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _FloorArrowButton extends StatelessWidget {
  const _FloorArrowButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFEEEEEE) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: disabled ? const Color(0xFFDDDDDD) : const Color(0xFF1A1A1A),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: disabled ? const Color(0xFFAAAAAA) : const Color(0xFF1A1A1A),
          size: 24,
        ),
      ),
    );
  }
}

class _Anomaly {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _Anomaly({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _EndlessResultOverlay extends ConsumerStatefulWidget {
  const _EndlessResultOverlay({
    required this.isVictory,
    required this.floor,
    required this.ink,
    required this.paint,
    required this.xp,
    required this.newBest,
    required this.onClose,
  });

  final bool isVictory;
  final int floor;
  final int ink;
  final int paint;
  final int xp;
  final bool newBest;
  final VoidCallback onClose;

  @override
  ConsumerState<_EndlessResultOverlay> createState() => _EndlessResultOverlayState();
}

class _EndlessResultOverlayState extends ConsumerState<_EndlessResultOverlay> {
  bool _adWatched = false;
  bool _isWatchingAd = false;

  void _onWatchAd() {
    if (_adWatched || _isWatchingAd) return;
    setState(() => _isWatchingAd = true);
    
    BattleAdsService.instance.showDoubleRewardAd(
      onRewarded: () async {
        try {
          await ref.read(walletProvider.notifier).awardMultiple(
            ink: widget.ink,
            paint: widget.paint,
            source: 'endless_floor_reward',
          );
        } catch (e) {
          debugPrint('Endless double reward grant (ink/paint) failed: $e');
        }
        try {
          await ref.read(accountLevelProvider.notifier).addXp(widget.xp);
        } catch (e) {
          debugPrint('Endless double reward grant (xp) failed: $e');
        }
        
        if (mounted) {
          setState(() {
            _adWatched = true;
            _isWatchingAd = false;
          });
          unawaited(HapticFeedback.mediumImpact());
        }
      },
      onDismissed: () {
        if (mounted) {
          setState(() => _isWatchingAd = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const inkColor = Color(0xFF1A1A1A);
    const gold = Color(0xFF00E5FF);
    final displayedInk = _adWatched ? widget.ink * 2 : widget.ink;
    final displayedPaint = _adWatched ? widget.paint * 2 : widget.paint;
    final displayedXp = _adWatched ? widget.xp * 2 : widget.xp;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: Center(
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: inkColor, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 10,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                widget.isVictory ? Icons.emoji_events : Icons.heart_broken_rounded,
                color: widget.isVictory ? gold : const Color(0xFFCC2222),
                size: 64,
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 12),


              Text(
                widget.isVictory ? 'VICTORY!' : 'DEFEATED!',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 32,
                  letterSpacing: 4,
                  color: widget.isVictory ? gold : const Color(0xFFCC2222),
                ),
              ),
              const SizedBox(height: 4),

              Text(
                widget.isVictory ? 'FLOOR ${widget.floor} CONQUERED' : 'FALLEN ON FLOOR ${widget.floor}',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              if (widget.newBest) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: gold, width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, color: gold, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'NEW BEST FLOOR RECORD!',
                        style: TextStyle(
                          color: Color(0xFFC5A000),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(delay: 200.ms, duration: 250.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
              ],


              if (widget.isVictory) ...[
                const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                const SizedBox(height: 8),
                const Text(
                  'REWARDS ACQUIRED',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _RewardBadge(icon: Icons.currency_bitcoin, label: '+$displayedInk INK', color: Colors.blue),
                    _RewardBadge(icon: Icons.brush, label: '+$displayedPaint PAINT', color: Colors.purple),
                    _RewardBadge(icon: Icons.military_tech, label: '+$displayedXp XP', color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                const SizedBox(height: 12),
                if (!_adWatched)
                  GestureDetector(
                    onTap: _onWatchAd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isWatchingAd)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                            )
                          else
                            const Icon(Icons.play_circle_outline, color: AppColors.ink, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'WATCH AD  ×2 REWARDS',
                            style: TextStyle(
                              fontFamily: 'Bangers',
                              fontSize: 13,
                              letterSpacing: 2,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
                        SizedBox(width: 8),
                        Text(
                          '×2 REWARDS CLAIMED',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 12,
                            letterSpacing: 1.5,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ] else ...[
                const Text(
                  'The arena is cruel. Strengthen your synth\'s equipment and attachments and return to battle!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
              const SizedBox(height: 24),


              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'RETURN TO BASE',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 16,
                        letterSpacing: 3,
                        color: Colors.white,
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

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SynthBadge extends ConsumerWidget {
  const _SynthBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const inkColor = Color(0xFF1A1A1A);
    final charId = ref.watch(equippedCharacterIdProvider);
    final allChars = CharacterDatabase.all;
    final activeChar = allChars.firstWhere((c) => c.id == charId, orElse: () => allChars.first);
    final levelData = ref.watch(characterLevelFamily(activeChar.id));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: inkColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: Border.all(color: inkColor, width: 1.2),
            ),
            child: activeChar.thumbnailAsset != null
                ? Image.asset(activeChar.thumbnailAsset!)
                : const Icon(Icons.person, color: inkColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeChar.name.toUpperCase(),
                  style: const TextStyle(
                    color: inkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SYNTH LEVEL ${levelData.level}',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
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
