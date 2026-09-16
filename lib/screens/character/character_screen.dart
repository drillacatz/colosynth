import 'package:colosynth/screens/character/stats_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_data/character_database.dart';
import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/service_providers.dart';
import 'package:colosynth/guide/guide_anchor.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/character/character_wheel.dart';
import 'package:colosynth/screens/character/character_misc.dart';
import 'package:colosynth/screens/character/equipment_panel.dart';
import 'package:colosynth/services/account_sync_service.dart';

enum CharacterTab { stats, equipment, synths, skills }

class CharacterScreen extends ConsumerStatefulWidget {
  const CharacterScreen({super.key});

  @override
  ConsumerState<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends ConsumerState<CharacterScreen> {
  int _selectedIndex = 0;
  CharacterTab _activeTab = CharacterTab.stats;

  @override
  void initState() {
    super.initState();
    final sm = ref.read(saveManagerProvider);
    final equippedId = sm.loadEquippedCharacter() ?? 'arthur';
    final chars = CharacterDatabase.all;

    final idx = chars.indexWhere((c) => c.id == equippedId);
    if (idx >= 0) _selectedIndex = idx;
  }

  @override
  void dispose() {
    AccountSyncService.instance.flushMilestone();
    super.dispose();
  }

  void _onCharacterSelected(int index, List<CharacterData> chars) {
    if (index == _selectedIndex) return;
    ComicButton.playButtonSfx();
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    final character = chars[index];
    ref
        .read(equippedCharacterIdProvider.notifier)
        .setEquippedCharacter(character.id);
  }

  Widget _buildTabContent(CharacterData selected) {
    switch (_activeTab) {
      case CharacterTab.stats:
        return CharacterLevelStats(character: selected);
      case CharacterTab.equipment:
        return CharacterEquipmentPanel(character: selected);
      case CharacterTab.synths:
        return CharacterSynthsPanel(character: selected);
      case CharacterTab.skills:
        return CharacterSkills(character: selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(unlockedCharactersProvider);
    final unlockedSet = <String>{...unlocked, 'arthur'};
    final allChars = CharacterDatabase.all;

    if (allChars.isEmpty) return const SizedBox.shrink();

    final safeIndex = _selectedIndex.clamp(0, allChars.length - 1);
    final selected = allChars[safeIndex];
    final levelData = ref.watch(characterLevelFamily(selected.id));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(child: CharacterArtBackdrop(character: selected)),
        Positioned(
          left: 10,
          right: 10,
          bottom: 12,
          height: 244,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.paperWhite.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.ink.withValues(alpha: 0.16),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 48,
                    child: CharacterScreenSidebar(
                      activeTab: _activeTab,
                      onSelected: (tab) => setState(() => _activeTab = tab),
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 20,
                  thickness: 1,
                  color: AppColors.ink.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: ClipRect(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: _buildTabContent(selected),
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 150.ms)
              .slideY(begin: 0.1, end: 0, duration: 300.ms),
        ),
        Positioned(
          top: 72,
          left: 16,
          right: 16,
          child: RepaintBoundary(
            child: CharacterNameBar(
              character: selected,
              level: levelData.level,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
        ),
        Positioned.fill(
          child: GuideAnchor(
            id: 'character_wheel',
            child: CharacterRouletteWheel(
              characters: allChars,
              unlockedIds: unlockedSet,
              initialIndex: safeIndex,
              onSelected: (idx) => _onCharacterSelected(idx, allChars),
            ),
          ),
        ),
      ],
    );
  }
}

class CharacterScreenSidebar extends StatelessWidget {
  const CharacterScreenSidebar({
    super.key,
    required this.activeTab,
    required this.onSelected,
  });

  final CharacterTab activeTab;
  final ValueChanged<CharacterTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paperWhite.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.ink.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(CharacterTab.values.length, (i) {
          final tab = CharacterTab.values[i];
          final isSelected = tab == activeTab;

          IconData icon;
          switch (tab) {
            case CharacterTab.stats:
              icon = Icons.bar_chart;
              break;
            case CharacterTab.equipment:
              icon = Icons.shield_outlined;
              break;
            case CharacterTab.synths:
              icon = Icons.hub;
              break;
            case CharacterTab.skills:
              icon = Icons.bolt;
              break;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: i == CharacterTab.values.length - 1 ? 0 : 10.0,
            ),
            child: GuideAnchor(
              id: 'char_tab_${tab.name}',
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(tab);
                },
                child: CharacterSidebarSlot(
                  icon: icon,
                  isSelected: isSelected,
                  accentColor: AppColors.ink,
                  size: 32.0,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class CharacterSidebarSlot extends StatelessWidget {
  const CharacterSidebarSlot({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.size,
  });

  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isSelected
            ? AppColors.comicBlue
            : AppColors.sketchGray.withValues(alpha: 0.18),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(isSelected ? 3.0 : 2.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isSelected
                ? AppColors.paperWhite.withValues(alpha: 0.14)
                : AppColors.paperWhite.withValues(alpha: 0.8),
            border: isSelected
                ? Border.all(
                    color: AppColors.paperWhite.withValues(alpha: 0.30),
                    width: 1.0,
                  )
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              color: isSelected
                  ? AppColors.paperWhite
                  : AppColors.ink.withValues(alpha: 0.4),
              size: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}
