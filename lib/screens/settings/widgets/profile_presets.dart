import 'package:flutter/material.dart';

class ProfilePresetAvatar {
  final String id;
  final String label;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  const ProfilePresetAvatar({
    required this.id,
    required this.label,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class ProfilePresetBanner {
  final String id;
  final String title;
  final List<Color> gradientColors;
  final IconData icon;

  const ProfilePresetBanner({
    required this.id,
    required this.title,
    required this.gradientColors,
    required this.icon,
  });
}

abstract final class ProfilePresets {
  static const List<ProfilePresetAvatar> avatars = [
    ProfilePresetAvatar(
      id: 'synth',
      label: 'Synth Warrior',
      icon: Icons.shield_outlined,
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF1A1A1A),
    ),
    ProfilePresetAvatar(
      id: 'cyber',
      label: 'Cybersynth',
      icon: Icons.memory_rounded,
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF001E3C),
    ),
    ProfilePresetAvatar(
      id: 'shadow',
      label: 'Shadow Ninja',
      icon: Icons.security_rounded,
      primaryColor: Color(0xFFA855F7),
      secondaryColor: Color(0xFF180E29),
    ),
    ProfilePresetAvatar(
      id: 'crown',
      label: 'Golden Crown',
      icon: Icons.emoji_events_rounded,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFF2D1F00),
    ),
    ProfilePresetAvatar(
      id: 'phoenix',
      label: 'Fire Phoenix',
      icon: Icons.local_fire_department_rounded,
      primaryColor: Color(0xFFFF3D00),
      secondaryColor: Color(0xFF3E0A00),
    ),
    ProfilePresetAvatar(
      id: 'mech',
      label: 'Mech Ace',
      icon: Icons.smart_toy_rounded,
      primaryColor: Color(0xFF00E676),
      secondaryColor: Color(0xFF022B14),
    ),
  ];

  static const List<ProfilePresetBanner> banners = [
    ProfilePresetBanner(
      id: 'cyber_synth',
      title: 'Cyber Synth',
      gradientColors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      icon: Icons.auto_awesome_mosaic_rounded,
    ),
    ProfilePresetBanner(
      id: 'comic_neon',
      title: 'Comic Neon',
      gradientColors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      icon: Icons.flash_on_rounded,
    ),
    ProfilePresetBanner(
      id: 'golden_arena',
      title: 'Golden Arena',
      gradientColors: [Color(0xFFF2994A), Color(0xFFF2C94C)],
      icon: Icons.emoji_events_rounded,
    ),
    ProfilePresetBanner(
      id: 'deep_ink',
      title: 'Deep Ink',
      gradientColors: [Color(0xFF111111), Color(0xFF232526)],
      icon: Icons.brush_rounded,
    ),
    ProfilePresetBanner(
      id: 'ruby_strike',
      title: 'Ruby Strike',
      gradientColors: [Color(0xFFEB3349), Color(0xFFF45C43)],
      icon: Icons.whatshot_rounded,
    ),
  ];

  static ProfilePresetAvatar getAvatar(String id) {
    return avatars.firstWhere(
      (a) => a.id == id,
      orElse: () => avatars.first,
    );
  }

  static ProfilePresetBanner getBanner(String id) {
    return banners.firstWhere(
      (b) => b.id == id,
      orElse: () => banners.first,
    );
  }
}
