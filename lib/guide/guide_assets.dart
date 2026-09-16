import 'package:colosynth/services/sprite_repository.dart';

/// Centralized helper for resolving asset paths used in guide sequences
/// (portraits, backgrounds, and voice tracks).
///
/// Provides graceful fallbacks for missing assets to prevent crashes.
abstract final class GuideAssets {

  /// Resolves the asset path for a voice line or sound effect.
  /// Audio files are expected under `assets/audio/story/`.
  static String voicePath(String fileName) {
    if (fileName.startsWith('story/')) return fileName;
    return 'story/$fileName';
  }


  /// Resolves the portrait image path for a speaking character.
  ///
  /// - If [isCustom] is true, looks in `assets/images/story/`.
  /// - Otherwise, delegates to [SpriteRepository] for standard characters.
  /// - Falls back to `assets/images/battle_ready.png` if nothing is found.
  static String portraitPath(String characterId, {bool isCustom = false}) {
    if (isCustom) {
      return 'assets/images/story/portrait_$characterId.png';
    }
    return SpriteRepository.characterFullBody(characterId);
  }

  /// Fallback portrait for characters whose assets are missing.
  static const String fallbackPortrait = 'assets/images/battle_ready.png';


  /// Resolves full-screen background graphic paths for narrative scenes.
  static String backgroundPath(String bgName) {
    return 'assets/images/story/bg_$bgName.png';
  }
}
