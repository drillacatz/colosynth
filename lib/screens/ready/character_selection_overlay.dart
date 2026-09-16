import 'package:flutter/material.dart';
import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class CharacterSelectionOverlay extends StatelessWidget {
  const CharacterSelectionOverlay({
    super.key,
    required this.allChars,
    required this.unlockedIds,
    required this.selectedId,
    required this.onSelect,
    required this.onClose,
  });

  final List<CharacterData> allChars;
  final Set<String> unlockedIds;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              const Text(
                'SELECT CHARACTER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontFamily: 'Bangers',
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: allChars.length,
                  itemBuilder: (context, index) {
                    final char = allChars[index];
                    final isUnlocked = unlockedIds.contains(char.id);
                    final isSelected = char.id == selectedId;

                    return GestureDetector(
                      onTap: isUnlocked ? () => onSelect(char.id) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.comicYellow
                                : Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.comicYellow
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                  )
                                ]
                              : [],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: isUnlocked ? 1.0 : 0.3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: char.thumbnailAsset != null
                                      ? Image.asset(char.thumbnailAsset!,
                                          fit: BoxFit.cover)
                                      : const Icon(Icons.person,
                                          color: Colors.white24, size: 40),
                                ),
                              ),
                            ),
                            if (!isUnlocked)
                              const Center(
                                child: Icon(Icons.lock,
                                    color: Colors.white70, size: 32),
                              ),
                            if (isSelected)
                              const Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(Icons.check_circle,
                                    color: AppColors.comicYellow, size: 20),
                              ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  char.name.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Bangers',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              ComicButton(
                label: 'CONFIRM',
                style: PBStyle.white,
                onTap: onClose,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                leading: const Icon(Icons.check, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
