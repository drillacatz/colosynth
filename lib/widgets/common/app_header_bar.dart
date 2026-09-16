import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/widgets/common/app_comic_button.dart';

/// Atomic header bar for screens featuring back action, title, and actions/badges.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.showBack = true,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (showBack)
              AppComicButton(
                label: 'BACK',
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                style: AppButtonStyle.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                fontSize: 14,
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 24,
                  color: AppColors.ink,
                  letterSpacing: 3,
                ),
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: actions!)
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
