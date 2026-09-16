import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:colosynth/services/achievement_service.dart';

class GameServicesPanel extends StatefulWidget {
  const GameServicesPanel({super.key});
  @override
  State<GameServicesPanel> createState() => _GameServicesPanelState();
}

class _GameServicesPanelState extends State<GameServicesPanel> {
  bool _isLoading = false;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final signedIn = await AchievementService.instance.checkAuthStatus();
    if (mounted) {
      setState(() {
        _isSignedIn = signedIn;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    final success = await AchievementService.instance.signIn(manual: true);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSignedIn = success;
      });
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    await AchievementService.instance.signOut();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSignedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = Platform.isAndroid ? 'GOOGLE PLAY GAMES' : 'GAME CENTER';
    final logo = Platform.isAndroid ? Icons.sports_esports_rounded : Icons.games_rounded;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(logo, color: _isSignedIn ? const Color(0xFF4CAF50) : const Color(0xFF888888), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isSignedIn ? 'SIGNED IN (ACHIEVEMENTS ACTIVE)' : 'NOT SIGNED IN',
                      style: TextStyle(color: _isSignedIn ? const Color(0xFF4CAF50) : const Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)),
              ),
            )
          else if (_isSignedIn)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => AchievementService.instance.showAchievements(),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFF1A1A1A), width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: const Text('ACHIEVEMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleSignOut,
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFCC2222), side: const BorderSide(color: Color(0xFFCC2222), width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: const Text('SIGN OUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: _handleSignIn,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('SIGN IN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
        ],
      ),
    );
  }
}
