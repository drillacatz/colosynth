import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/navigation_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/service_providers.dart';
import 'package:colosynth/providers/store_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/services/review_service.dart';

import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/arena/arena_screen.dart';
import 'package:colosynth/screens/character/character_screen.dart';
import 'package:colosynth/screens/home/bottom_bar.dart';
import 'package:colosynth/screens/overlays/level_up_overlay.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';
import 'package:colosynth/screens/inventory/inventory_screen.dart';
import 'package:colosynth/screens/store/store_screen.dart';
import 'package:colosynth/screens/upgrade/upgrade_screen.dart';
import 'package:colosynth/screens/overlays/top_overlay.dart';
import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/guide/guide_controller.dart';
import 'package:colosynth/guide/ui/guide_overlay.dart';
import 'package:colosynth/providers/daily_checkin_provider.dart';
import 'package:colosynth/screens/overlays/daily_checkin_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<int> _loadedTabs = {NavigationNotifier.arenaIndex};


  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  static const _tabs = [
    TabInfo(
        icon: Icons.store_outlined,
        activeIcon: Icons.store,
        label: 'STORE',
        feature: UnlockableFeature.store),
    TabInfo(
        icon: Icons.upgrade_outlined,
        activeIcon: Icons.upgrade,
        label: 'UPGRADE',
        feature: UnlockableFeature.upgradeTab),
    TabInfo(
        icon: Icons.sports_martial_arts_outlined,
        activeIcon: Icons.sports_martial_arts,
        label: 'ARENA'),
    TabInfo(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'CHARACTER',
        feature: UnlockableFeature.characterScreen),
    TabInfo(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'INVENTORY'),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    AudioService.instance.playBgm(BgmTrack.home);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final checkInState = ref.read(dailyCheckInProvider);
      if (!checkInState.isClaimedToday || checkInState.missedYesterday) {
        DailyCheckInDialog.show(context);
      }
    });
  }



  void _onTabTap(int index) {
    final currentIdx = ref.read(navigationProvider);
    final playerLevel = ref.read(accountLevelProvider.select((l) => l.accountLevel));
    final tabToken = _tabs[index];

    if (index == 3) {
      final tutorialDone = ref.read(tutorialCompletedProvider);
      if (!tutorialDone) {
        LockedFeatureOverlay.show(
          context,
          customTitle: 'Characters Locked',
          customDescription: 'Complete the training ground tutorial levels first to unlock Characters!',
          customConditionText: 'Complete Tutorial',
          customEmoji: '🛡️',
        );
        return;
      }
    }

    if (index == 1) {
      final stagesCleared = ref.read(tournamentProgressProvider).keys.where((k) => !k.startsWith('tutorial_')).length;
      if (stagesCleared < 3) {
        LockedFeatureOverlay.show(
          context,
          customTitle: 'Upgrade Locked',
          customDescription: 'Clear 3 or more tournament stages to unlock the Upgrade tab.',
          customConditionText: 'Clear ${3 - stagesCleared} more stage(s)',
          customEmoji: '⚡',
        );
        return;
      }
    }

    if (tabToken.feature != null &&
        !ProgressionService.instance
            .isUnlocked(tabToken.feature!, playerLevel)) {
      _showLockedMessage(
          index,
          ProgressionService.instance.requiredLevel(tabToken.feature!),
          playerLevel,
          tabToken.feature!);
      return;
    }

    if (index == 0) {
      final dailyInk = ref.read(dailyInkProvider).value;
      final isAdFree = ref.read(adFreeProvider).value ?? false;
      final hasClaimable = dailyInk != null &&
          dailyInk.slots.isNotEmpty &&
          (!dailyInk.slots[0].claimed || (isAdFree && !dailyInk.allClaimed));
      if (hasClaimable) {
        ref.read(storeSectionProvider.notifier).setSection(StoreSection.daily);
      }
    }

    if (index == currentIdx) {
      _navKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    ref.read(analyticsServiceProvider).logTabChanged(tabToken.label);

    _loadedTabs.add(index);
    ref.read(navigationProvider.notifier).selectTab(index);

    HapticFeedback.selectionClick();
  }

  void _showLockedMessage(
    int tabIndex,
    int required,
    int current,
    UnlockableFeature feature,
  ) {
    LockedFeatureOverlay.show(
      context,
      feature: feature,
      requiredLevel: required,
      currentLevel: current,
    );
  }

  void _goToStore(StoreSection section) {
    ref.read(storeSectionProvider.notifier).setSection(section);
    _onTabTap(0);
  }

  Widget _buildTabRoot(int index) {
    switch (index) {
      case 0:
        return const StoreScreen();
      case 1:
        return const UpgradeScreen();
      case 2:
        return const ArenaScreen();
      case 3:
        return const CharacterScreen();
      case 4:
        return const InventoryScreen();
      default:
        throw StateError('Unknown index');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationProvider);
    final accountLevel = ref.watch(accountLevelProvider.select((l) => l.accountLevel));


    ref.listen<int>(navigationProvider, (prev, next) {
      final guideState = ref.read(guideControllerProvider);
      if (guideState.isActive) {
        switch (next) {
          case 0:
            ref.read(guideControllerProvider.notifier).notifyAction('navigate_to_store');
            break;
          case 2:
            ref.read(guideControllerProvider.notifier).notifyAction('navigate_to_arena');
            break;
          case 3:
            ref.read(guideControllerProvider.notifier).notifyAction('navigate_to_character');
            break;
        }
      }
    });

    ref.listen<int>(
      accountLevelProvider.select((l) => l.accountLevel),
      (prev, next) {
        if (prev == null || next <= prev) return;
        final unlocks = ProgressionService.instance.newlyUnlocked(prev, next);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          LevelUpOverlay.show(context, newLevel: next, newUnlocks: unlocks);
          ReviewService.instance.maybeRequestReview(next);
        });
      },
    );

    final svc = ProgressionService.instance;
    final tabUnlocked = _tabs.map((t) {
      return t.feature == null ||
          svc.isUnlocked(t.feature!, accountLevel);
    }).toList();

    final dailyInk = ref.watch(dailyInkProvider).value;
    final isAdFree = ref.watch(adFreeProvider).value ?? false;
    final showStoreRedDot = tabUnlocked[0] &&
        dailyInk != null &&
        dailyInk.slots.isNotEmpty &&
        (!dailyInk.slots[0].claimed || (isAdFree && !dailyInk.allClaimed));

    final showRedDots = [
      showStoreRedDot,
      false,
      false,
      false,
      false,
    ];

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: GameBottomBar(
        selectedIndex: selectedIndex,
        tabs: _tabs,
        tabUnlocked: tabUnlocked,
        onTap: _onTabTap,
        showRedDots: showRedDots,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: NotebookBackground()),
          SafeArea(
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: List.generate(5, (i) {
                if (!_loadedTabs.contains(i)) {
                  return const SizedBox.shrink();
                }
                return TickerMode(
                  enabled: i == selectedIndex,
                  child: Offstage(
                    offstage: i != selectedIndex,
                    child: RepaintBoundary(
                      child: Navigator(
                        key: _navKeys[i],
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (_) => _buildTabRoot(i),
                        ),
                      ),
                    ),
                  ),
                ).animate(target: i == selectedIndex ? 1 : 0).fade(
                      duration: 180.ms,
                      curve: Curves.easeIn,
                    );
              }),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopOverlay(
              visible: true,
              onInkAdd: () => _goToStore(StoreSection.ink),
              onPaintAdd: () => _goToStore(StoreSection.paint),
              onSynthKeyTap: () => _goToStore(StoreSection.synth),
            ),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navState = _navKeys[selectedIndex].currentState;
        if (navState != null && navState.canPop()) {
          navState.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        child: Stack(
          children: [
            scaffold,
            const GuideOverlay(),
          ],
        ),
      ),
    );

  }
}
