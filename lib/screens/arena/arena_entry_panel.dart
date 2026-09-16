import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/guide/guide_anchor.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/tournament/tournament_screen.dart';
import 'package:colosynth/screens/roguelike/roguelike_screen.dart';

enum ArenaMode { tournament, roguelike }

class ArenaModeNotifier extends Notifier<ArenaMode> {
  @override
  ArenaMode build() => ArenaMode.tournament;

  void toggle() {
    state = state == ArenaMode.tournament
        ? ArenaMode.roguelike
        : ArenaMode.tournament;
  }
}

final arenaModeProvider = NotifierProvider<ArenaModeNotifier, ArenaMode>(
  ArenaModeNotifier.new,
);

class ArenaEntryPanel extends ConsumerWidget {
  const ArenaEntryPanel({
    super.key,
    required this.endlessUnlocked,
  });

  final bool endlessUnlocked;

  void _onStart(BuildContext context, WidgetRef ref, ArenaMode mode) {
    if (mode == ArenaMode.roguelike) {
      if (!endlessUnlocked) return;
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const RoguelikeShell()),
      );
    } else {
      Navigator.push<void>(
        context,
        PageRouteBuilder<void>(
          pageBuilder: (_, anim, __) => const TournamentScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 260),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(arenaModeProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mode == ArenaMode.roguelike ? 'MODE: ROGUELIKE' : 'MODE: TOURNAMENT',
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 14,
            letterSpacing: 4,
            color: Color(0xFF1A0E00),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GuideAnchor(
              id: 'arena_start_button',
              child: (mode == ArenaMode.roguelike && !endlessUnlocked
                      ? LockedArenaButton(
                          label: 'START',
                          requiredLevel: ProgressionService.instance
                              .requiredLevel(UnlockableFeature.endlessBattle),
                        )
                      : ComicButton(
                          label: 'START',
                          style: mode == ArenaMode.roguelike
                              ? PBStyle.white
                              : PBStyle.dark,
                          fontSize: 18,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 15),
                          onTap: () => _onStart(context, ref, mode),
                        ))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
            ),
            const SizedBox(width: 10),
            GuideAnchor(
              id: 'arena_mode_toggle',
              child: ComicSquareBtn(
                icon: mode == ArenaMode.roguelike
                    ? Icons.emoji_events
                    : Icons.casino,
                onTap: () => ref.read(arenaModeProvider.notifier).toggle(),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class ComicSquareBtn extends StatefulWidget {
  const ComicSquareBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool showBadge;

  @override
  State<ComicSquareBtn> createState() => _ComicSquareBtnState();
}

class _ComicSquareBtnState extends State<ComicSquareBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final showBadge = widget.showBadge;

    return AnimatedOpacity(
      opacity: disabled ? 0.35 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: disabled
            ? null
            : (_) {
                HapticFeedback.lightImpact();
                ComicButton.playButtonSfx();
                setState(() => _isPressed = true);
              },
        onTapUp: disabled
            ? null
            : (_) {
                widget.onTap?.call();
                setState(() => _isPressed = false);
              },
        onTapCancel: disabled ? null : () => setState(() => _isPressed = false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              painter: SquareDoodlePainter(),
              child: const SizedBox(width: 54, height: 54),
            ),
            Positioned.fill(
              child: Center(
                child:
                    Icon(widget.icon, color: const Color(0xFF1A0E00), size: 22),
              ),
            ),
            if (showBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFFDFDFB), width: 1.5),
                  ),
                ),
              ),
          ],
        ).animate(target: _isPressed ? 1 : 0).scale(
            begin: const Offset(1, 1),
            end: const Offset(0.9, 0.9),
            duration: 80.ms),
      ),
    );
  }
}

class SquareDoodlePainter extends CustomPainter {
  SquareDoodlePainter();

  Offset _jitter(Offset p) => p;

  Path _doodlePath(Rect rect) {
    const r = 5.0, segs = 3;
    final corners = [
      Offset(rect.left + r, rect.top),
      Offset(rect.right - r, rect.top),
      Offset(rect.right, rect.top + r),
      Offset(rect.right, rect.bottom - r),
      Offset(rect.right - r, rect.bottom),
      Offset(rect.left + r, rect.bottom),
      Offset(rect.left, rect.bottom - r),
      Offset(rect.left, rect.top + r),
    ];
    final path = Path()..moveTo(corners[0].dx, corners[0].dy);
    void wobbly(Offset from, Offset to) {
      for (int i = 1; i <= segs; i++) {
        path.lineTo(_jitter(Offset.lerp(from, to, i / segs)!).dx,
            _jitter(Offset.lerp(from, to, i / segs)!).dy);
      }
    }

    wobbly(corners[0], corners[1]);
    path.quadraticBezierTo(_jitter(Offset(rect.right, rect.top)).dx,
        _jitter(Offset(rect.right, rect.top)).dy, corners[2].dx, corners[2].dy);
    wobbly(corners[2], corners[3]);
    path.quadraticBezierTo(
        _jitter(Offset(rect.right, rect.bottom)).dx,
        _jitter(Offset(rect.right, rect.bottom)).dy,
        corners[4].dx,
        corners[4].dy);
    wobbly(corners[4], corners[5]);
    path.quadraticBezierTo(
        _jitter(Offset(rect.left, rect.bottom)).dx,
        _jitter(Offset(rect.left, rect.bottom)).dy,
        corners[6].dx,
        corners[6].dy);
    wobbly(corners[6], corners[7]);
    path.quadraticBezierTo(_jitter(Offset(rect.left, rect.top)).dx,
        _jitter(Offset(rect.left, rect.top)).dy, corners[0].dx, corners[0].dy);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(_doodlePath(rect.translate(3, 3)),
        Paint()..color = const Color(0xFFD0C8C0));
    final facePath = _doodlePath(rect);
    canvas.drawPath(facePath, Paint()..color = const Color(0xFFFDFDFB));
    canvas.drawPath(
        facePath,
        Paint()
          ..color = const Color(0xFF1A0E00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class LockedArenaButton extends StatelessWidget {
  const LockedArenaButton(
      {super.key, required this.label, required this.requiredLevel});
  final String label;
  final int requiredLevel;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.38,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          ComicButton(
              label: label,
              style: PBStyle.white,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              onTap: null),
          Positioned(
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A0E00),
                  borderRadius: BorderRadius.circular(3)),
              child: Text('Lv$requiredLevel',
                  style: const TextStyle(
                      fontFamily: 'Bangers',
                      color: AppColors.pureWhite,
                      fontSize: 10,
                      letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

class RoguelikeShell extends StatelessWidget {
  const RoguelikeShell({super.key});

  @override
  Widget build(BuildContext context) {
    const gold = AppColors.ink;
    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      body: Column(
        children: [
          SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: gold.withValues(alpha: 0.4))),
                          child: const Icon(Icons.arrow_back,
                              color: gold, size: 20))),
                  const SizedBox(width: 14),
                  const Text('ENDLESS BATTLE',
                      style: TextStyle(
                          color: gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4)),
                ]),
              )),
          const RoguelikeScreen(),
        ],
      ),
    );
  }
}
