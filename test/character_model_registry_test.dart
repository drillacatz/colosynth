import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/character_viewer/character_model_registry.dart';

void main() {
  group('CharacterModelRegistry Tests', () {
    test('resolves registered character IDs correctly', () {
      final arthur = CharacterModelRegistry.resolve('arthur');
      expect(arthur, isNotNull);
      expect(arthur!.characterId, equals('arthur'));
      expect(arthur.glbPath, equals('assets/models/arthur.glb'));
      expect(arthur.availableAnimations, contains('idle'));
    });

    test('resolves prefixed char_ IDs correctly', () {
      final centrium = CharacterModelRegistry.resolve('char_centrium');
      expect(centrium, isNotNull);
      expect(centrium!.characterId, equals('centrium'));
    });

    test('returns null for unknown character ID without throwing', () {
      final unknown = CharacterModelRegistry.resolve('unknown_hero');
      expect(unknown, isNull);
      expect(CharacterModelRegistry.hasModel('unknown_hero'), isFalse);
    });

    test('accurately identifies bundled models vs definition-only models', () {
      expect(CharacterModelRegistry.isModelBundled('arthur'), isTrue);
      expect(CharacterModelRegistry.isModelBundled('char_arthur'), isTrue);
      expect(CharacterModelRegistry.isModelBundled('centrium'), isFalse);
      expect(CharacterModelRegistry.isModelBundled('char_centrium'), isFalse);
      expect(CharacterModelRegistry.isModelBundled('unknown_hero'), isFalse);
    });
  });
}
