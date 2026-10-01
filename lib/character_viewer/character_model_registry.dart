
/// Metadata definition for a 3D character model asset.
class CharacterModelAsset {
  final String characterId;
  final String glbPath;
  final String? posterPath;
  final String cameraOrbit;
  final String fieldOfView;
  final List<String> availableAnimations;

  const CharacterModelAsset({
    required this.characterId,
    required this.glbPath,
    this.posterPath,
    this.cameraOrbit = '0deg 75deg 105%',
    this.fieldOfView = '30deg',
    this.availableAnimations = const ['idle', 'reaction'],
  });
}

/// Central registry mapping character IDs to 3D asset metadata.
class CharacterModelRegistry {
  static const Map<String, CharacterModelAsset> _assets = {
    'arthur': CharacterModelAsset(
      characterId: 'arthur',
      glbPath: 'assets/models/arthur.glb',
      posterPath: 'assets/images/arthur.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'centrium': CharacterModelAsset(
      characterId: 'centrium',
      glbPath: 'assets/models/centrium.glb',
      posterPath: 'assets/images/centrium.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'lilith': CharacterModelAsset(
      characterId: 'lilith',
      glbPath: 'assets/models/lilith.glb',
      posterPath: 'assets/images/lilith.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'valkyrie': CharacterModelAsset(
      characterId: 'valkyrie',
      glbPath: 'assets/models/valkyrie.glb',
      posterPath: 'assets/images/valkyrie.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'kronos': CharacterModelAsset(
      characterId: 'kronos',
      glbPath: 'assets/models/kronos.glb',
      posterPath: 'assets/images/kronos.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'nyx': CharacterModelAsset(
      characterId: 'nyx',
      glbPath: 'assets/models/nyx.glb',
      posterPath: 'assets/images/nyx.png',
      availableAnimations: ['idle', 'reaction'],
    ),
  };

  /// Fallback GLB model path used when a specific character model is not yet bundled.
  static const String fallbackGlbPath = 'assets/models/base.glb';

  /// Set of models that are physically bundled on disk in assets/models/.
  static const Set<String> bundledModels = {'arthur', 'base'};

  /// Resolve character ID to 3D asset entry if available, falling back to base.glb if not bundled.
  static CharacterModelAsset? resolve(String characterId) {
    final key = characterId.toLowerCase().replaceAll('char_', '');
    final entry = _assets[key] ?? _assets[characterId];
    if (entry == null) return null;

    if (!bundledModels.contains(key)) {
      return CharacterModelAsset(
        characterId: entry.characterId,
        glbPath: fallbackGlbPath,
        posterPath: entry.posterPath,
        cameraOrbit: entry.cameraOrbit,
        fieldOfView: entry.fieldOfView,
        availableAnimations: entry.availableAnimations,
      );
    }
    return entry;
  }

  /// Check if character ID has a mapped 3D model asset definition.
  static bool hasModel(String characterId) {
    final key = characterId.toLowerCase().replaceAll('char_', '');
    return _assets.containsKey(key) || _assets.containsKey(characterId);
  }

  /// Check if character ID has a unique dedicated 3D model asset physically bundled.
  static bool isModelBundled(String characterId) {
    final key = characterId.toLowerCase().replaceAll('char_', '');
    return bundledModels.contains(key) && key != 'base';
  }

  /// Check if a 3D model can be rendered for this character (either dedicated or via base.glb fallback).
  static bool canRender3d(String characterId) {
    return hasModel(characterId);
  }
}
