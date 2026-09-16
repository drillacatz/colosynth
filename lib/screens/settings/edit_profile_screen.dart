import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:colosynth/providers/auth_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/service_providers.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';
import 'package:colosynth/services/achievement_service.dart';
import 'package:colosynth/services/battle_stats_service.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/services/sp_manager.dart';
import 'package:colosynth/screens/theme/background.dart';


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


class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  String? _saveError;
  bool _saved = false;
  bool _isAuthLoading = false;
  bool _googleRewardClaimed = true;
  bool _isPlayGamesSignedIn = false;
  bool _isPlayGamesLoading = false;
  bool _playGamesRewardClaimed = true;

  String _selectedAvatarId = 'synth';
  String _selectedBannerId = 'cyber_synth';

  @override
  void initState() {
    super.initState();
    final current = ref.read(displayNameProvider);
    _nameController = TextEditingController(text: current == 'Guest' ? '' : current);

    final prefs = ref.read(sharedPreferencesProvider);
    final savedAvatar = prefs.getString(SPKeys.customAvatarId);
    _selectedAvatarId = (savedAvatar == null || savedAvatar == 'gladiator') ? 'synth' : savedAvatar;
    _selectedBannerId = prefs.getString(SPKeys.customBannerId) ?? 'cyber_synth';

    _checkRewardStatus();
    _checkPlayGamesStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkRewardStatus() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        setState(() {
          _googleRewardClaimed = true;
        });
      }
      return;
    }

    final uid = user.uid;
    final prefs = ref.read(sharedPreferencesProvider);
    final userDataService = ref.read(userDataServiceProvider);

    final googleClaimed = await userDataService.hasClaimedLoginReward(uid, 'google', prefs: prefs);

    if (mounted) {
      setState(() {
        _googleRewardClaimed = googleClaimed;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isAuthLoading = true;
      _saveError = null;
    });
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogleDetailed();
      if (!mounted) return;
      setState(() => _isAuthLoading = false);

      if (result.isSuccess) {
        await _checkRewardStatus();
        await _tryClaimGoogleReward();
        if (mounted) {
          final newName = ref.read(displayNameProvider);
          _nameController.text = newName == 'Guest' ? '' : newName;
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthLoading = false;
        _saveError = e.toString();
      });
    }
  }

  Future<void> _tryClaimGoogleReward() async {
    if (_googleRewardClaimed) return;
    final user = ref.read(authStateProvider).value;
    if (user == null || user.isAnonymous) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final userDataService = ref.read(userDataServiceProvider);
    final didClaim = await userDataService.claimLoginReward(
      user.uid, 'google', prefs: prefs,
    );

    if (didClaim && mounted) {
      await ref
          .read(walletProvider.notifier)
          .award(Currency.paint, 50, source: 'login_reward_google');

      setState(() => _googleRewardClaimed = true);

      if (mounted) {
        _showRewardSnackBar(context, 'Google Sign-In Reward: +50 🎨 Paint!');
      }
    }
  }

  void _showRewardSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFCC02), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isAuthLoading = true;
      _saveError = null;
    });
    try {
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        setState(() {
          _isAuthLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthLoading = false;
          _saveError = 'Failed to sign out of Google. Please try again.';
        });
      }
    }
  }

  Future<void> _checkPlayGamesStatus() async {
    setState(() => _isPlayGamesLoading = true);
    final isPG = await AchievementService.instance.checkAuthStatus();
    if (mounted) {
      setState(() {
        _isPlayGamesSignedIn = isPG;
        _isPlayGamesLoading = false;
      });
      if (isPG) {
        await _checkPlayGamesRewardStatus();
      }
    }
  }

  Future<void> _checkPlayGamesRewardStatus() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        setState(() {
          _playGamesRewardClaimed = true;
        });
      }
      return;
    }

    final uid = user.uid;
    final prefs = ref.read(sharedPreferencesProvider);
    final userDataService = ref.read(userDataServiceProvider);

    final pgClaimed = await userDataService.hasClaimedLoginReward(uid, 'play_games', prefs: prefs);

    if (mounted) {
      setState(() {
        _playGamesRewardClaimed = pgClaimed;
      });
    }
  }

  Future<void> _handlePlayGamesSignIn() async {
    setState(() {
      _isPlayGamesLoading = true;
      _saveError = null;
    });
    try {
      final success = await AchievementService.instance.signIn(manual: true);
      if (mounted) {
        setState(() {
          _isPlayGamesSignedIn = success;
          _isPlayGamesLoading = false;
        });
      }
      if (success) {
        await _checkPlayGamesRewardStatus();
        await _tryClaimPlayGamesReward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlayGamesLoading = false;
          _saveError = e.toString();
        });
      }
    }
  }

  Future<void> _tryClaimPlayGamesReward() async {
    if (_playGamesRewardClaimed) return;
    final user = ref.read(authStateProvider).value;
    if (user == null || user.isAnonymous) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final userDataService = ref.read(userDataServiceProvider);
    final didClaim = await userDataService.claimLoginReward(
      user.uid, 'play_games', prefs: prefs,
    );

    if (didClaim && mounted) {
      await ref
          .read(walletProvider.notifier)
          .award(Currency.paint, 50, source: 'login_reward_play_games');

      setState(() => _playGamesRewardClaimed = true);

      if (mounted) {
        _showRewardSnackBar(context, 'Play Games Reward: +50 🎨 Paint!');
      }
    }
  }

  Future<void> _handlePlayGamesSignOut() async {
    setState(() {
      _isPlayGamesLoading = true;
      _saveError = null;
    });
    try {
      await AchievementService.instance.signOut();
      if (mounted) {
        setState(() {
          _isPlayGamesSignedIn = false;
          _isPlayGamesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlayGamesLoading = false;
          _saveError = 'Failed to sign out of Game Services. Please try again.';
        });
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _saveError = 'Display name cannot be empty.');
      return;
    }
    if (name.length > 24) {
      setState(() => _saveError = 'Max 24 characters.');
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final uid = ref.read(authServiceProvider).currentUser?.uid ?? 'local_guest_offline';
      final userDataService = ref.read(userDataServiceProvider);

      await userDataService.saveCustomDisplayName(uid, name, prefs: prefs);
      await prefs.setString(SPKeys.customAvatarId, _selectedAvatarId);
      await prefs.setString(SPKeys.customBannerId, _selectedBannerId);

      ref.invalidate(displayNameProvider);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _saved = true;
        });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'Failed to save. Please try again.';
        });
      }
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SELECT AVATAR',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 18,
                      letterSpacing: 2,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF888888)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: ProfilePresets.avatars.length,
                itemBuilder: (_, i) {
                  final preset = ProfilePresets.avatars[i];
                  final isSelected = _selectedAvatarId == preset.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarId = preset.id);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: preset.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? preset.primaryColor : const Color(0xFF1A1A1A),
                          width: isSelected ? 3.0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: preset.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(preset.icon, color: preset.primaryColor, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            preset.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? preset.primaryColor : Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showBannerPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROFILE BACKGROUND',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 18,
                      letterSpacing: 2,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF888888)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ProfilePresets.banners.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final b = ProfilePresets.banners[i];
                    final isSelected = _selectedBannerId == b.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedBannerId = b.id);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 130,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: b.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                            width: isSelected ? 3.0 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(b.icon, color: Colors.white, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              b.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Bangers',
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(isGuestProvider);
    final photoUrl = ref.watch(authStateProvider).value?.photoURL;
    final googleName = ref.watch(authStateProvider).value?.displayName;
    final levelData = ref.watch(accountLevelProvider);
    final stats = BattleStatsService.instance;

    final totalBattles = stats.totalBattles;
    final wins = stats.totalWins;
    final losses = totalBattles - wins;
    final winRate = totalBattles > 0
        ? ((wins / totalBattles) * 100).toStringAsFixed(1)
        : '—';
    final streak = stats.longestWinStreak;
    final currentStreak = stats.currentWinStreak;
    final totalXp = levelData.accountXp;

    final currentAvatar = ProfilePresets.getAvatar(_selectedAvatarId);
    final currentBanner = ProfilePresets.getBanner(_selectedBannerId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'PROFILE & STATS',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontFamily: 'Bangers',
            fontSize: 20,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.12),
            height: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: NotebookBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: _showBannerPicker,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentBanner.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BannerPatternPainter(),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.palette_outlined, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  currentBanner.title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: -40,
                  child: GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentAvatar.secondaryColor,
                            border: Border.all(color: currentAvatar.primaryColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: photoUrl != null
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      currentAvatar.icon,
                                      color: currentAvatar.primaryColor,
                                      size: 46,
                                    ),
                                  )
                                : Icon(
                                    currentAvatar.icon,
                                    color: currentAvatar.primaryColor,
                                    size: 46,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 52),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISPLAY NAME',
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF1A1A1A),
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      maxLength: 24,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 _\-\.]')),
                      ],
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        hintText: isGuest ? 'Enter a display name…' : (googleName ?? 'Your name'),
                        hintStyle: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        counterStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 10),
                        suffixIcon: _nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFFAAAAAA), size: 16),
                                onPressed: () => setState(() => _nameController.clear()),
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() => _saveError = null),
                    ),
                  ),

                  if (_saveError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _saveError!,
                      style: const TextStyle(color: Color(0xFFCC2222), fontSize: 12),
                    ),
                  ],

                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: (_isSaving || _saved) ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _saved
                            ? const Color(0xFF2E7D32)
                            : _isSaving
                                ? const Color(0xFF1A1A1A).withValues(alpha: 0.5)
                                : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _saved || _isSaving
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0xFF1A1A1A),
                                  offset: Offset(2, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else if (_saved)
                            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20)
                          else
                            const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _saved ? 'SAVED!' : _isSaving ? 'SAVING…' : 'SAVE NAME & PRESETS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Bangers',
                              fontSize: 15,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (isGuest || !_isPlayGamesSignedIn) ...[
                    Text(
                      'CONNECT ACCOUNTS',
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (isGuest) ...[
                    GestureDetector(
                      onTap: _isAuthLoading ? null : _handleGoogleSignIn,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF1A1A1A),
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: _isAuthLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 28),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'SIGN IN WITH GOOGLE',
                                    style: TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontFamily: 'Bangers',
                                      fontSize: 15,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  if (!_googleRewardClaimed) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E5FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '+50 🎨',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (!_isPlayGamesSignedIn) ...[
                    GestureDetector(
                      onTap: _isPlayGamesLoading ? null : _handlePlayGamesSignIn,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF1A1A1A),
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: _isPlayGamesLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Platform.isAndroid
                                        ? Icons.sports_esports_rounded
                                        : Icons.games_rounded,
                                    color: const Color(0xFF4CAF50),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Platform.isAndroid
                                        ? 'SIGN IN WITH PLAY GAMES'
                                        : 'SIGN IN WITH GAME CENTER',
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontFamily: 'Bangers',
                                      fontSize: 15,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  if (!_playGamesRewardClaimed) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E5FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '+50 🎨',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFD0D0D0), thickness: 1),
                  const SizedBox(height: 20),

                  _WinRateDonutCard(
                    wins: wins,
                    losses: losses,
                    winRate: winRate,
                    total: totalBattles,
                    currentStreak: currentStreak,
                    bestStreak: streak,
                  ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.08, end: 0),

                  const SizedBox(height: 24),

                  const _SectionLabel(label: 'BATTLE RECORD'),
                  const SizedBox(height: 10),

                  _StatsGrid(
                    items: [
                      _StatItem(
                        icon: Icons.sports_martial_arts,
                        label: 'TOTAL BATTLES',
                        value: '$totalBattles',
                      ),
                      _StatItem(
                        icon: Icons.emoji_events_outlined,
                        label: 'VICTORIES',
                        value: '$wins',
                        valueColor: const Color(0xFF1A7A3A),
                      ),
                      _StatItem(
                        icon: Icons.close_rounded,
                        label: 'DEFEATS',
                        value: '$losses',
                        valueColor: const Color(0xFFCC2222),
                      ),
                      _StatItem(
                        icon: Icons.percent,
                        label: 'WIN RATE',
                        value: winRate == '—' ? '—' : '$winRate%',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const _SectionLabel(label: 'STREAKS'),
                  const SizedBox(height: 10),

                  _StatsGrid(
                    items: [
                      _StatItem(
                        icon: Icons.local_fire_department_outlined,
                        label: 'CURRENT STREAK',
                        value: '$currentStreak',
                        valueColor: currentStreak > 0 ? const Color(0xFFE07000) : null,
                      ),
                      _StatItem(
                        icon: Icons.military_tech_outlined,
                        label: 'BEST STREAK',
                        value: '$streak',
                        valueColor: streak >= 5 ? const Color(0xFFE07000) : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const _SectionLabel(label: 'COMBAT PERFORMANCE'),
                  const SizedBox(height: 10),

                  _StatsGrid(
                    items: [
                      _StatItem(
                        icon: Icons.shield_outlined,
                        label: 'TOTAL PARRIES',
                        value: ProgressionService.fmtInk(stats.totalParries),
                      ),
                      _StatItem(
                        icon: Icons.gavel_rounded,
                        label: 'TOTAL BREAKS',
                        value: ProgressionService.fmtInk(stats.totalBroken),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const _SectionLabel(label: 'PROGRESSION'),
                  const SizedBox(height: 10),

                  _StatsGrid(
                    items: [
                      _StatItem(
                        icon: Icons.trending_up,
                        label: 'ACCOUNT LEVEL',
                        value: '${levelData.accountLevel}',
                      ),
                      _StatItem(
                        icon: Icons.star_border_rounded,
                        label: 'TOTAL XP EARNED',
                        value: ProgressionService.fmtInk(totalXp.toInt()),
                      ),
                      _StatItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'CONSECUTIVE LOGINS',
                        value: '${stats.consecutiveLogins} DAYS',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const _SectionLabel(label: 'TOURNAMENTS'),
                  const SizedBox(height: 10),

                  _StatsGrid(
                    items: [
                      _StatItem(
                        icon: Icons.workspace_premium_outlined,
                        label: 'EASY WINS',
                        value: '${stats.tournamentWins('easy')}',
                      ),
                      _StatItem(
                        icon: Icons.workspace_premium_outlined,
                        label: 'MEDIUM WINS',
                        value: '${stats.tournamentWins('medium')}',
                      ),
                      _StatItem(
                        icon: Icons.workspace_premium_outlined,
                        label: 'HARD WINS',
                        value: '${stats.tournamentWins('hard')}',
                      ),
                      _StatItem(
                        icon: Icons.workspace_premium_outlined,
                        label: 'EXTREME WINS',
                        value: '${stats.tournamentWins('extreme')}',
                        valueColor: const Color(0xFFCC9900),
                      ),
                    ],
                  ),

                  if (!isGuest) ...[
                    const SizedBox(height: 32),
                    const Divider(color: Color(0xFFD0D0D0), thickness: 1),
                    const SizedBox(height: 20),
                    Text(
                      'ACCOUNT SIGN OUT',
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: _isAuthLoading ? null : _handleSignOut,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCC2222), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFCC2222),
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isAuthLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFCC2222),
                                ),
                              )
                            else ...[
                              const Icon(Icons.logout_rounded, color: Color(0xFFCC2222), size: 18),
                              const SizedBox(width: 10),
                              const Text(
                                'SIGN OUT OF GOOGLE ACCOUNT',
                                style: TextStyle(
                                  color: Color(0xFFCC2222),
                                  fontFamily: 'Bangers',
                                  fontSize: 15,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isPlayGamesSignedIn) ...[
                      GestureDetector(
                        onTap: _isPlayGamesLoading ? null : _handlePlayGamesSignOut,
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCC2222), width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFCC2222),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isPlayGamesLoading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFCC2222),
                                  ),
                                )
                              else ...[
                                const Icon(Icons.logout_rounded, color: Color(0xFFCC2222), size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  Platform.isAndroid
                                      ? 'SIGN OUT OF PLAY GAMES'
                                      : 'SIGN OUT OF GAME CENTER',
                                  style: const TextStyle(
                                    color: Color(0xFFCC2222),
                                    fontFamily: 'Bangers',
                                    fontSize: 15,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }
}


class _WinRateDonutCard extends StatelessWidget {
  const _WinRateDonutCard({
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.total,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int wins;
  final int losses;
  final String winRate;
  final int total;
  final int currentStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final winRatio = total > 0 ? (wins / total).clamp(0.0, 1.0) : 0.0;
    final lossRatio = total > 0 ? (losses / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1A1A1A),
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BATTLE WIN RATE',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 17,
                  letterSpacing: 2,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$total TOTAL BATTLES',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    winRatio: winRatio,
                    lossRatio: lossRatio,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          winRate == '—' ? '—' : '$winRate%',
                          style: const TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 22,
                            color: Color(0xFF1A1A1A),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'WIN RATE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF888888),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  children: [
                    _ChartLegendItem(
                      color: const Color(0xFF00E676),
                      label: 'VICTORIES',
                      value: '$wins',
                    ),
                    const SizedBox(height: 10),
                    _ChartLegendItem(
                      color: const Color(0xFFFF1744),
                      label: 'DEFEATS',
                      value: '$losses',
                    ),
                    const SizedBox(height: 10),
                    _ChartLegendItem(
                      color: const Color(0xFFFFAB00),
                      label: 'BEST STREAK',
                      value: '$bestStreak WINS',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double winRatio;
  final double lossRatio;

  _DonutChartPainter({required this.winRatio, required this.lossRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (winRatio <= 0 && lossRatio <= 0) return;

    final startAngle = -math.pi / 2;

    if (winRatio > 0) {
      final winSweep = 2 * math.pi * winRatio;
      final winPaint = Paint()
        ..color = const Color(0xFF00E676)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        winSweep,
        false,
        winPaint,
      );
    }

    if (lossRatio > 0) {
      final lossSweep = 2 * math.pi * lossRatio;
      final lossStart = startAngle + (2 * math.pi * winRatio);
      final lossPaint = Paint()
        ..color = const Color(0xFFFF1744)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        lossStart,
        lossSweep,
        false,
        lossPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) =>
      oldDelegate.winRatio != winRatio || oldDelegate.lossRatio != lossRatio;
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
              letterSpacing: 1.0,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}


class _BannerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.5;

    for (double i = -size.height; i < size.width; i += 24) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final a = items[i];
      final b = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _StatCell(item: a)),
              if (b != null) ...[
                const SizedBox(width: 12),
                Expanded(child: _StatCell(item: b)),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: const Color(0xFFAAAAAA), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  style: TextStyle(
                    color: item.valueColor ?? const Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(color: Color(0xFFD0D0D0), thickness: 1),
        ),
      ],
    );
  }
}
