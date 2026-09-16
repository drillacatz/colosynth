
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
      posterPath: 'assets/images/characters/arthur.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'centrium': CharacterModelAsset(
      characterId: 'centrium',
      glbPath: 'assets/models/centrium.glb',
      posterPath: 'assets/images/characters/centrium.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'lilith': CharacterModelAsset(
      characterId: 'lilith',
      glbPath: 'assets/models/lilith.glb',
      posterPath: 'assets/images/characters/lilith.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'valkyrie': CharacterModelAsset(
      characterId: 'valkyrie',
      glbPath: 'assets/models/valkyrie.glb',
      posterPath: 'assets/images/characters/valkyrie.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'kronos': CharacterModelAsset(
      characterId: 'kronos',
      glbPath: 'assets/models/kronos.glb',
      posterPath: 'assets/images/characters/kronos.png',
      availableAnimations: ['idle', 'reaction'],
    ),
    'nyx': CharacterModelAsset(
      characterId: 'nyx',
      glbPath: 'assets/models/nyx.glb',
      posterPath: 'assets/images/characters/nyx.png',
      availableAnimations: ['idle', 'reaction'],
    ),
  };

  /// Set of models that are physically bundled on disk in assets/models/.
  static const Set<String> bundledModels = {'arthur'};

  /// Resolve character ID to 3D asset entry if available.
  static CharacterModelAsset? resolve(String characterId) {
    final key = characterId.toLowerCase().replaceAll('char_', '');
    return _assets[key] ?? _assets[characterId];
  }

  /// Check if character ID has a mapped 3D model asset definition.
  static bool hasModel(String characterId) {
    return resolve(characterId) != null;
  }

  /// Check if character ID has a 3D model asset physically bundled and ready to render.
  static bool isModelBundled(String characterId) {
    final key = characterId.toLowerCase().replaceAll('char_', '');
    return bundledModels.contains(key);
  }
}
