import 'package:flutter/material.dart';
import 'package:colosynth/screens/settings/edit_profile_screen.dart';

class SynthProfileCard extends StatelessWidget {
  const SynthProfileCard({
    super.key,
    required this.displayName,
    required this.isGuest,
    this.photoUrl,
    this.isGoogleSignedIn = false,
    this.isPlayGamesSignedIn = false,
    this.onEditFinished,
  });

  final String displayName;
  final bool isGuest;
  final String? photoUrl;
  final bool isGoogleSignedIn;
  final bool isPlayGamesSignedIn;
  final VoidCallback? onEditFinished;

  static const _ink = Color(0xFF1A1A1A);
  static const _sub = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isGoogleSignedIn
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.6)
                          : const Color(0xFF888888),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: _sub, size: 30),
                          )
                        : const Icon(Icons.person, color: _sub, size: 30),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _StatusDot(active: isGoogleSignedIn),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        displayName.toUpperCase(),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isGuest) ...[
                      const SizedBox(width: 6),
                      _GuestBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      isGuest ? 'GUEST MODE' : 'RANK: INITIATE',
                      style: const TextStyle(
                        color: _sub,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _CloudSyncStatusBadge(isCloudSynced: !isGuest),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF888888),
              size: 20,
            ),
            tooltip: 'Edit profile',
            splashRadius: 20,
            onPressed: () async {
              await Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const EditProfileScreen(),
                ),
              );
              onEditFinished?.call();
            },
          ),
        ],
      ),
    );
  }
}


/// Green dot = signed in, grey dot = not signed in.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF4CAF50) : const Color(0xFFBBBBBB),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: active
          ? const Icon(Icons.check, color: Colors.white, size: 7)
          : null,
    );
  }
}

/// Small red exclamation badge shown next to display name when guest.
class _GuestBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFCC2222),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CloudSyncStatusBadge extends StatelessWidget {
  const _CloudSyncStatusBadge({required this.isCloudSynced});
  final bool isCloudSynced;

  @override
  Widget build(BuildContext context) {
    final color = isCloudSynced ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCloudSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isCloudSynced ? 'CLOUD SYNCED' : 'LOCAL SAVE',
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
