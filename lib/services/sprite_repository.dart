/// Centralized repository for all sprite and image asset paths in the game.
/// This includes game-world sprites loaded via Flame and UI assets loaded
/// via Flutter's Image.asset.
abstract final class SpriteRepository {

  /// Enemy sprite path relative to Flame's default images folder (assets/images/).
  static const String enemy = 'enemy.png';

  /// Player fallback sprite path.
  static const String player = 'player.png';

  /// Resolves the character sprite image path relative to Flame's default images folder (assets/images/).
  static String characterSprite(String id) {
    final cleanId = id.toLowerCase().replaceAll('char_', '');
    return '$cleanId.png';
  }

  /// Player block overlay/effect sprite path.
  static const String blockEffect = 'vfx/vfx_shield_barrier.png';

  /// Resolves the character animation frame path relative to Flame's asset folder.
  /// Escapes Flame's default 'assets/images' prefix.
  static String characterFrame(String characterId, String animName, int frameIndex) {
    return '../assets/animation/${characterId}_$animName/$frameIndex.png';
  }


  /// Character full body asset path.
  static String characterFullBody(String id) => 'assets/images/$id.png';

  /// Character thumbnail asset path.
  static String characterThumbnail(String id) => 'assets/images/$id.png';

  /// Character selection overlay portrait path.
  static String characterPortrait(String id) => 'assets/images/$id.png';

  /// Tournament tier image path.
  static String tournamentTier(int tier) => 'assets/images/t$tier.png';

  /// Extreme tournament image path.
  static String get extremeTournament => 'assets/images/extreme1.png';

  /// Resolves general store/shop product asset path (without file extension).
  static String storeItem(String baseName) => 'assets/images/$baseName';

  /// Equipment image path.
  static String equipmentImage(String id) => 'assets/images/$id.png';

  /// Lottie splash animation path.
  static String get splashLottie => 'assets/animation/splash.json';

  static const String battleBackgroundNotebook = 'assets/images/bg_notebook.png';
  static const String battleBackgroundComicBurst = 'assets/images/bg_comic_burst.png';
  static const String battleBackgroundDarkComic = 'assets/images/bg_dark_comic.png';
  static const String battleBackgroundSynthwaveArena = 'assets/images/bg_battle_arena.png';
  static const String readyScreenBackground = 'assets/images/bg_ready_screen.png';

  /// Resolves the appropriate battle background PNG asset path based on tournament tier.
  static String battleBackgroundForTier(int tier) {
    if (tier >= 5) return battleBackgroundSynthwaveArena;
    if (tier >= 3) return battleBackgroundDarkComic;
    if (tier >= 2) return battleBackgroundComicBurst;
    return battleBackgroundNotebook;
  }

  /// Resolves the appropriate boss sprite image path relative to Flame's default images folder (assets/images/).
  static String bossSpriteForTier(int tier) {
    if (tier >= 7) return 'boss_dragon.png';
    if (tier >= 4) return 'boss_cyber.png';
    return 'boss_chalk.png';
  }

  /// Skill VFX sprite sheet path relative to Flame images folder (assets/images/).
  static String skillVfx(String archetype) {
    const valid = {
      'slash',
      'lightning',
      'arcane_nuke',
      'fire_blast',
      'shield_barrier',
      'holy_light',
    };
    final key = valid.contains(archetype) ? archetype : 'slash';
    return 'vfx/vfx_$key.png';
  }

  /// Resolves the skill VFX archetype and whether it targets the enemy (true) or self (false).
  static (String archetype, bool targetEnemy) vfxInfoForCharacter(String characterId) {
    final clean = characterId.toLowerCase();
    switch (clean) {
      case 'lilith':
        return ('arcane_nuke', true);
      case 'centrium':
        return ('lightning', true);
      case 'char_04':
        return ('shield_barrier', false);
      case 'char_05':
        return ('holy_light', true);
      case 'char_06':
        return ('slash', true);
      case 'char_07':
        return ('holy_light', false);
      case 'char_08':
        return ('fire_blast', false);
      case 'char_09':
        return ('slash', true);
      case 'char_10':
        return ('fire_blast', true);
      case 'char_11':
        return ('arcane_nuke', true);
      case 'char_12':
        return ('slash', true);
      case 'arthur':
      default:
        return ('slash', true);
    }
  }
}

