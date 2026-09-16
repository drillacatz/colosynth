import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:colosynth/game_data/character_database.dart';

import 'package:colosynth/game/ai/ai_profiles.dart';
import 'package:colosynth/providers/battle_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/screens/theme/tokens.dart';

import 'package:colosynth/screens/ready/battle_ready_widgets.dart';
import 'package:colosynth/screens/ready/zigzag_lightning.dart';
import 'package:colosynth/screens/ready/character_selection_overlay.dart';
import 'package:colosynth/screens/ready/battle_alert_overlay.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

class ReadyResult {
  final bool confirmed;
  final String characterId;
  const ReadyResult({required this.confirmed, required this.characterId});
}

final selectedCharIdProvider =
    NotifierProvider<SelectedCharNotifier, String>(SelectedCharNotifier.new);

class SelectedCharNotifier extends Notifier<String> {
  @override
  String build() {
    final equipped = ref.watch(equippedCharacterIdProvider);
    final unlocked = ref.watch(unlockedCharactersProvider);
    final allChars = CharacterDatabase.all;
    final unlockedSet = {...unlocked, 'arthur'};
    if (unlockedSet.contains(equipped)) {
      return equipped;
    }
    return allChars
        .firstWhere(
          (c) => unlockedSet.contains(c.id),
          orElse: () => allChars.first,
        )
        .id;
  }

  @override
  set state(String value) => super.state = value;
}

class ReadyScreen extends ConsumerStatefulWidget {
  const ReadyScreen({
    super.key,
    required this.enemyId,
    required this.enemyName,
    required this.aiProfile,
    required this.tournamentTier,
    required this.isBoss,
    this.isExtreme = false,
    this.skipLightningEntrance = false,
  });

  final String enemyId;
  final String enemyName;
  final AiProfile aiProfile;
  final int tournamentTier;
  final bool isBoss;
  final bool isExtreme;
  final bool skipLightningEntrance;

  @override
  ConsumerState<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends ConsumerState<ReadyScreen> {
  bool _showOverlay = false;
  bool _showBattleAlert = false;
  late bool _lightningFinished;

  @override
  void initState() {
    super.initState();
    _lightningFinished = widget.skipLightningEntrance;
    AudioService.instance.playBgm(BgmTrack.ready);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final c in CharacterDatabase.all) {
        if (c.thumbnailAsset != null) {
          precacheImage(AssetImage(c.thumbnailAsset!), context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final levelData = ref.watch(charLevelProvider);
    final stats = ref.watch(battleStatsProvider);
    final unlocked = ref.watch(unlockedCharactersProvider);

    final selectedId = ref.watch(selectedCharIdProvider);
    const allChars = CharacterDatabase.all;
    final unlockedSet = {...unlocked, 'arthur'};
    final activeChar = allChars.firstWhere((c) => c.id == selectedId,
        orElse: () => allChars.first);

    return stats.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error loading stats: $err')),
      ),
      data: (battleStats) {
        final size = MediaQuery.sizeOf(context);
        final double yDiv = size.height - 370;
        final double xTop = size.width * 0.44;
        final double xBot = size.width * 0.48;
        const double sw = 40.0;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                if (_lightningFinished)
                  ClipPath(
                    clipper: ReadyQuadrantClipper(
                      quadrant: 1,
                      yDivisor: yDiv,
                      xTopBase: xTop,
                      xBottomBase: xBot,
                      slantedWidth: sw,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF0D0600),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: -20,
                            width: size.width * 0.55,
                            bottom: 370,
                            child: Opacity(
                              opacity: 0.9,
                              child: activeChar.fullBodyAsset != null
                                  ? Image.asset(
                                      activeChar.fullBodyAsset!,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.bottomLeft,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 120.ms)
                      .slideX(begin: -1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

                if (_lightningFinished)
                  ClipPath(
                    clipper: ReadyQuadrantClipper(
                      quadrant: 2,
                      yDivisor: yDiv,
                      xTopBase: xTop,
                      xBottomBase: xBot,
                      slantedWidth: sw,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF121212),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 100,
                            right: -6,
                            width: size.width * 0.52,
                            child: Transform.scale(
                              scale: 0.85,
                              alignment: Alignment.topRight,
                              child: CharacterDetailsColumn(
                                character: activeChar,
                                level: levelData.level,
                                hp: battleStats.hp,
                                atk: battleStats.atk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 140.ms)
                      .fadeIn(duration: 120.ms)
                      .slideX(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

                if (_lightningFinished)
                  ClipPath(
                    clipper: ReadyQuadrantClipper(
                      quadrant: 3,
                      yDivisor: yDiv,
                      xTopBase: xTop,
                      xBottomBase: xBot,
                      slantedWidth: sw,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF141414),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 130,
                            left: 24,
                            width: size.width * 0.44,
                            child: const EquipmentDetailsSection(),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 280.ms)
                      .fadeIn(duration: 120.ms)
                      .slideX(begin: -1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

                if (_lightningFinished)
                  ClipPath(
                    clipper: ReadyQuadrantClipper(
                      quadrant: 4,
                      yDivisor: yDiv,
                      xTopBase: xTop,
                      xBottomBase: xBot,
                      slantedWidth: sw,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF121212),
                      child: const Stack(
                        children: [
                          SizedBox.shrink(),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 420.ms)
                      .fadeIn(duration: 120.ms)
                      .slideX(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

                Positioned.fill(
                  child: IgnorePointer(
                    child: LightningDivisor(
                      key: const ValueKey('ready_lightning_divisor'),
                      segments: [
                        (Offset(xTop + sw, 0), Offset(xTop, yDiv)),
                        (Offset(xTop, yDiv), Offset(xBot + sw, yDiv)),
                        (Offset(xBot + sw, yDiv), Offset(xBot, size.height)),
                      ],
                      thickness: 4.5,
                      entranceDuration: const Duration(milliseconds: 380),
                      skipEntrance: _lightningFinished || widget.skipLightningEntrance,
                      onEntranceFinished: () {
                        if (!mounted) return;
                        if (!_lightningFinished) {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _lightningFinished = true;
                          });
                        }
                      },
                    ),
                  ),
                ),

                if (_lightningFinished)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 10,
                    left: 16,
                    child: ReadyBackButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context, rootNavigator: true).pop(
                          ReadyResult(confirmed: false, characterId: selectedId),
                        );
                      },
                    ),
                  )
                      .animate(delay: 540.ms)
                      .fadeIn(duration: 200.ms),

                if (_lightningFinished)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.paddingOf(context).bottom + 20,
                    child: Row(
                      children: [
                        ComicButton(
                          label: '',
                          leading: const Icon(Icons.swap_horiz,
                              color: Colors.black, size: 24),
                          style: PBStyle.white,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _showOverlay = true);
                          },
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: EnterBattleButton(
                            isBoss: widget.isBoss,
                            isExtreme: widget.isExtreme,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() => _showBattleAlert = true);
                            },
                          ),
                        ),
                      ],
                    )
                        .animate(delay: 540.ms)
                        .fadeIn(duration: 200.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),
                  ),


                if (_showOverlay)
                  CharacterSelectionOverlay(
                    allChars: allChars,
                    unlockedIds: unlockedSet,
                    selectedId: selectedId,
                    onSelect: (id) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(selectedCharIdProvider.notifier).state = id;
                      });
                    },
                    onClose: () => setState(() => _showOverlay = false),
                  ),

                if (_showBattleAlert)
                  BattleAlertOverlay(
                    onFinished: () {
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pop(
                          ReadyResult(confirmed: true, characterId: selectedId),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
