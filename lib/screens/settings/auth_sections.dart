import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class GuestAuthSection extends StatelessWidget {
  const GuestAuthSection({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.onGoogleSignIn,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
          ),
          child: Column(
            children: [
              const Text(
                'SIGN IN TO SYNC PROGRESS, UNLOCK ACHIEVEMENTS & LEADERBOARDS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _GoogleSignInButton(
                isLoading: isLoading,
                onPressed: onGoogleSignIn,
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class AccountManagementPanel extends StatelessWidget {
  const AccountManagementPanel({
    super.key,
    required this.isLoading,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final bool isLoading;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      ),
      child: Column(
        children: [
          _AccountTile(
            label: 'SIGN OUT',
            icon: Icons.logout,
            isLoading: isLoading,
            onTap: onSignOut,
          ),
          const Divider(
            color: Color(0xFFE8E8E8),
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          _AccountTile(
            label: 'DELETE ACCOUNT',
            icon: Icons.delete_outline,
            isLoading: isLoading,
            onTap: onDeleteAccount,
            labelColor: const Color(0xFFCC2222),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
    this.labelColor,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading
          ? null
          : () {
              ComicButton.playButtonSfx();
              onTap();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF666666),
                ),
              )
            else
              Icon(icon,
                  color: labelColor ?? const Color(0xFF888888), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? const Color(0xFF1A1A1A),
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: labelColor ?? const Color(0xFF888888), size: 16),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              ComicButton.playButtonSfx();
              onPressed();
            },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
