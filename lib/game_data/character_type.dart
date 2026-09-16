import 'package:flutter/material.dart';
import 'package:colosynth/services/sprite_repository.dart';

enum CharacterRarity { common, rare, epic, legendary }

@immutable
class CharacterSkill {
  const CharacterSkill({
    required this.name,
    required this.description,
    required this.icon,
  });

  final String name;
  final String description;
  final IconData icon;
}

@immutable
class CharacterStat {
  const CharacterStat({required this.label, required this.value, this.displayValue});

  final String label;
  final int value;
  final String? displayValue;
}

@immutable
class CharacterData {
  const CharacterData({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    required this.accentColor,
    required this.stats,
    required this.activeSkill,
    required this.passiveSkill,
    required this.icon,
    required this.paintCost,
    required this.rarity,
    this.hoursLeft = 0,
    String? fullBodyAsset,
    String? thumbnailAsset,
  })  : _fullBodyAsset = fullBodyAsset,
        _thumbnailAsset = thumbnailAsset;

  final String id;
  final String name;
  final String role;
  final String description;
  final Color accentColor;
  final List<CharacterStat> stats;
  final CharacterSkill activeSkill;
  final CharacterSkill passiveSkill;
  final IconData icon;
  final int paintCost;
  final CharacterRarity rarity;
  final int hoursLeft;
  final String? _fullBodyAsset;
  final String? _thumbnailAsset;

  String? get fullBodyAsset =>
      _fullBodyAsset ?? SpriteRepository.characterFullBody(id);
  String? get thumbnailAsset =>
      _thumbnailAsset ?? SpriteRepository.characterThumbnail(id);

  String get rarityLabel {
    if (paintCost == 0) return 'STARTER (UNLOCKED)';
    switch (rarity) {
      case CharacterRarity.legendary:
        return 'LEGENDARY';
      case CharacterRarity.epic:
        return 'EPIC';
      case CharacterRarity.rare:
        return 'RARE';
      case CharacterRarity.common:
        return 'COMMON';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case CharacterRarity.legendary:
        return const Color(0xFFFF4400);
      case CharacterRarity.epic:
        return const Color(0xFF8B5CF6);
      case CharacterRarity.rare:
        return const Color.fromARGB(255, 0, 169, 253);
      case CharacterRarity.common:
        return const Color.fromARGB(255, 253, 254, 255);
    }
  }
}


