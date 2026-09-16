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
  static const String blockEffect = 'block.png';

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

  /// Resolves the appropriate battle background PNG asset path based on tournament tier.
  static String battleBackgroundForTier(int tier) {
    if (tier >= 7) return battleBackgroundDarkComic;
    if (tier >= 4) return battleBackgroundComicBurst;
    return battleBackgroundNotebook;
  }
}

