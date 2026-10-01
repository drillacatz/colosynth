import 'dart:io' show Platform;
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
import 'package:colosynth/services/sp_manager.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/settings/stats_screen.dart';
import 'package:colosynth/widgets/transitions/diagonal_slice_route.dart';

import 'package:colosynth/screens/settings/widgets/profile_presets.dart';
import 'package:colosynth/screens/settings/widgets/profile_picker_sheets.dart';

export 'package:colosynth/screens/settings/widgets/profile_presets.dart';
export 'package:colosynth/screens/settings/widgets/profile_picker_sheets.dart';


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

      if (!mounted) return;
      setState(() => _googleRewardClaimed = true);

      _showRewardSnackBar(context, 'Google Sign-In Reward: +50 🎨 Paint!');
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

      if (!mounted) return;
      setState(() => _playGamesRewardClaimed = true);

      _showRewardSnackBar(context, 'Play Games Reward: +50 🎨 Paint!');
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
    showProfileAvatarPicker(
      context,
      selectedAvatarId: _selectedAvatarId,
      onSelected: (id) => setState(() => _selectedAvatarId = id),
    );
  }

  void _showBannerPicker() {
    showProfileBannerPicker(
      context,
      selectedBannerId: _selectedBannerId,
      onSelected: (id) => setState(() => _selectedBannerId = id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(isGuestProvider);
    final photoUrl = ref.watch(authStateProvider).value?.photoURL;
    final googleName = ref.watch(authStateProvider).value?.displayName;
    final stats = BattleStatsService.instance;

    final totalBattles = stats.totalBattles;
    final wins = stats.totalWins;
    final losses = totalBattles - wins;
    final winRate = totalBattles > 0
        ? ((wins / totalBattles) * 100).toStringAsFixed(1)
        : '—';

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

                  _CareerStatsShortcutCard(
                    wins: wins,
                    losses: losses,
                    winRate: winRate,
                    totalBattles: totalBattles,
                    onTap: () {
                      ComicButton.playButtonSfx();
                      Navigator.of(context).push(
                        DiagonalSlicePageRoute<void>(
                          builder: (_) => const StatsScreen(),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.06, end: 0),

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


class _CareerStatsShortcutCard extends StatelessWidget {
  const _CareerStatsShortcutCard({
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.totalBattles,
    required this.onTap,
  });

  final int wins;
  final int losses;
  final String winRate;
  final int totalBattles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.8),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'CAREER & STATS',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 16,
                      letterSpacing: 1.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VIEW ALL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 12, color: Color(0xFF1A1A1A)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(label: 'BATTLES', value: '$totalBattles'),
                  Container(width: 1, height: 24, color: const Color(0xFFDDDDDD)),
                  _MiniStat(label: 'WINS', value: '$wins', color: const Color(0xFF1A7A3A)),
                  Container(width: 1, height: 24, color: const Color(0xFFDDDDDD)),
                  _MiniStat(label: 'DEFEATS', value: '$losses', color: const Color(0xFFCC2222)),
                  Container(width: 1, height: 24, color: const Color(0xFFDDDDDD)),
                  _MiniStat(label: 'WIN RATE', value: winRate == '—' ? '—' : '$winRate%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 16,
            color: color ?? const Color(0xFF1A1A1A),
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
