import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/auth_provider.dart';
import 'package:colosynth/services/auth_service.dart';
import 'package:colosynth/services/achievement_service.dart';
import 'package:colosynth/screens/settings/profile_card.dart';

class ProfilePanel extends ConsumerStatefulWidget {
  const ProfilePanel({super.key});

  @override
  ConsumerState<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends ConsumerState<ProfilePanel> {
  String? _authError;

  bool _isPlayGamesSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkPlayGamesStatus();
  }

  Future<void> _checkPlayGamesStatus() async {
    final signedIn = await AchievementService.instance.checkAuthStatus();
    if (mounted) {
      setState(() {
        _isPlayGamesSignedIn = signedIn;
      });
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (mounted) setState(() => _authError = e.toString());
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
        ),
        title: const Text(
          'DELETE ACCOUNT',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Bangers',
            fontSize: 14,
          ),
        ),
        content: const Text(
          'This will permanently delete your account and all saved progress. This action cannot be undone.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Color(0xFFCC2222))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authServiceProvider).deleteAccount();
    } catch (e) {
      if (mounted) setState(() => _authError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(isGuestProvider);
    final displayName = ref.watch(displayNameProvider);
    final photoUrl = ref.watch(authStateProvider).value?.photoURL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SynthProfileCard(
          displayName: displayName,
          isGuest: isGuest,
          photoUrl: photoUrl,
          isGoogleSignedIn: !isGuest,
          isPlayGamesSignedIn: _isPlayGamesSignedIn,
          onEditFinished: _checkPlayGamesStatus,
            ),
        if (!isGuest) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _handleSignOut,
                child: const Text(
                  'SIGN OUT',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Bangers',
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _handleDeleteAccount,
                child: const Text(
                  'DELETE ACCOUNT',
                  style: TextStyle(
                    color: Color(0xFFCC2222),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Bangers',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_authError != null) ...[
          const SizedBox(height: 8),
          Text(
            _authError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCC2222), fontSize: 12),
          ),
        ],
      ],
    );
  }
}
