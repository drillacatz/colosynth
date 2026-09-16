import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/character_viewer/character_model_registry.dart';
import 'package:colosynth/character_viewer/character_model_viewer.dart';
import 'package:colosynth/character_viewer/character_viewer_providers.dart';
import 'package:colosynth/screens/theme/shared_painters.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class CharacterArtBackdrop extends ConsumerWidget {
  const CharacterArtBackdrop({super.key, required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final is3dMode = ref.watch(characterViewer3dModeProvider);
    final has3dModel = CharacterModelRegistry.isModelBundled(character.id);

    Widget art;
    if (is3dMode && has3dModel) {
      art = CharacterModelViewer(
        characterId: character.id,
        height: size.height * 0.50,
        allowUserControl: true,
        autoRotate: true,
        showActionBar: true,
      );
    } else {
      art = character.fullBodyAsset != null
          ? Image.asset(
              character.fullBodyAsset!,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) =>
                  CharacterPlaceholder(character: character),
            )
          : CharacterPlaceholder(character: character);
    }

    return Positioned(
      left: 0,
      top: 156,
      width: size.width * 0.66,
      bottom: 0,
      child: art,
    );
  }
}

class CharacterPlaceholder extends StatelessWidget {
  const CharacterPlaceholder({super.key, required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sketchGray.withValues(alpha: 0.08),
            AppColors.sketchGray.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              color: AppColors.ink.withValues(alpha: 0.15),
              size: 120,
            ),
            const SizedBox(height: 8),
            Text(
              character.name.toUpperCase(),
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.20),
                fontSize: 13,
                letterSpacing: 6,
                fontFamily: 'Bangers',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CharacterNameBar extends ConsumerWidget {
  const CharacterNameBar({
    super.key,
    required this.character,
    this.level,
  });
  final CharacterData character;
  final int? level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final is3dMode = ref.watch(characterViewer3dModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomPaint(
              painter: NotebookCardPainter(
                seed: character.role.hashCode,
                faceColor: AppColors.comicBlue,
                borderColor: Colors.black.withValues(alpha: 0.15),
                borderWidth: 1.0,
                cornerRadius: 2.0,
                showShadow: true,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  character.role.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.paperWhite,
                    fontSize: 9,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Bangers',
                  ),
                ),
              ),
            ),
            if (level != null) ...[
              const SizedBox(width: 6),
              CustomPaint(
                painter: NotebookCardPainter(
                  seed: 777,
                  faceColor: AppColors.paperWhite,
                  borderColor: AppColors.ink.withValues(alpha: 0.35),
                  borderWidth: 1.0,
                  cornerRadius: 2.0,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Text(
                    'LV.$level',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Bangers',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ref.read(characterViewer3dModeProvider.notifier).state = !is3dMode;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: is3dMode ? AppColors.comicBlue : Colors.black45,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: is3dMode ? AppColors.comicBlue : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      is3dMode ? Icons.view_in_ar : Icons.portrait,
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      is3dMode ? '3D VIEW' : '2D ART',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bangers',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          character.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontFamily: 'Bangers',
            letterSpacing: 4,
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 14,
                offset: Offset(2, 3),
              ),
              Shadow(
                color: Color(0xBB000000),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CharacterPopArtBackground extends StatelessWidget {
  const CharacterPopArtBackground({super.key, this.accent});
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: CharacterPopArtBgPainter(accent: accent ?? AppColors.ink),
      ),
    );
  }
}

class PopArtLabel extends StatelessWidget {
  const PopArtLabel({super.key, required this.label, this.accent});
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.comicYellow,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0D0600),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          fontFamily: 'Bangers',
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}
