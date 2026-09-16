import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/guide/guide_controller.dart';
import 'package:colosynth/guide/guide_assets.dart';
import 'package:colosynth/guide/guide_anchor.dart';
import 'package:colosynth/guide/models/guide_step.dart';
import 'package:colosynth/guide/ui/coach_bubble.dart';
import 'package:colosynth/guide/ui/doodle_dialog_box.dart';
import 'package:colosynth/guide/ui/spotlight_mask.dart';
import 'package:colosynth/guide/ui/typewriter_text.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';

/// The main guide presentation overlay, rendered as a transparent layer
/// inside a [Stack]. Never pushed as a route — eliminates the "ghost pop" bug.
///
/// Auto-selects rendering mode based on [GuideStepType]:
/// - `dialogue` → Portrait + DoodleDialogBox + TypewriterText
/// - `coachMark` → CoachBubble positioned near anchor widget
/// - `spotlight` → SpotlightMask dimming + dialogue at bottom
/// - `action` → Instruction text with spotlight, waiting for user action
///
/// Usage in any screen's build method:
/// ```dart
/// Stack(
///   children: [
///     // ... screen content ...
///     const GuideOverlay(),
///   ],
/// )
/// ```
class GuideOverlay extends ConsumerWidget {
  const GuideOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideState = ref.watch(guideControllerProvider);

    if (!guideState.isActive) return const SizedBox.shrink();

    final step = guideState.currentStep;
    if (step == null) return const SizedBox.shrink();

    final guide = guideState.activeGuide!;

    Widget content;
    switch (step.type) {
      case GuideStepType.dialogue:
        content = _buildDialogueMode(context, ref, step, guideState, guide);
        break;
      case GuideStepType.coachMark:
        content = _buildCoachMarkMode(context, ref, step, guideState, guide);
        break;
      case GuideStepType.spotlight:
        content = _buildSpotlightMode(context, ref, step, guideState, guide);
        break;
      case GuideStepType.action:
        content = _buildActionMode(context, ref, step, guideState, guide);
        break;
    }

    return content;
  }

  bool _shouldPlaceBoxAtTop(BuildContext context, GuideStep step) {
    if (step.dialogPosition == GuideDialogPosition.top) return true;
    if (step.dialogPosition == GuideDialogPosition.bottom) return false;

    if (step.anchorId != null) {
      final rect = GuideAnchorRegistry.getRect(step.anchorId!);
      if (rect != null) {
        final screenSize = MediaQuery.sizeOf(context);
        if (rect.center.dy > screenSize.height * 0.45) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildPositionedDialogBox({
    required BuildContext context,
    required GuideStep step,
    required bool isTypingCompleted,
    required bool hasHighlight,
    required GuideController controller,
    VoidCallback? onTap,
  }) {
    final isTop = _shouldPlaceBoxAtTop(context, step);
    final childWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _buildDialogBox(step, isTypingCompleted, hasHighlight, controller),
    );

    if (isTop) {
      return Positioned(
        left: 16,
        right: 16,
        top: MediaQuery.paddingOf(context).top + 60,
        height: 180,
        child: childWidget,
      );
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 16,
      height: 180,
      child: childWidget,
    );
  }


  Widget _buildDialogueMode(
    BuildContext context,
    WidgetRef ref,
    GuideStep step,
    GuideState guideState,
    dynamic guide,
  ) {
    final controller = ref.read(guideControllerProvider.notifier);
    final isTop = _shouldPlaceBoxAtTop(context, step);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.advance(),
              child: const SizedBox.shrink(),
            ),
          ),

          Positioned.fill(
            top: isTop ? 230 : 0,
            bottom: isTop ? 0 : 230,
            child: SafeArea(child: _buildPortrait(step)),
          ),

          if (guide.isSkippable)
            _buildSkipButton(context, ref),

          _buildProgressIndicator(context, guideState),

          _buildPositionedDialogBox(
            context: context,
            step: step,
            isTypingCompleted: guideState.isTypingCompleted,
            hasHighlight: false,
            controller: controller,
            onTap: () => controller.advance(),
          ),
        ],
      ),
    );
  }


  Widget _buildCoachMarkMode(
    BuildContext context,
    WidgetRef ref,
    GuideStep step,
    GuideState guideState,
    dynamic guide,
  ) {
    final controller = ref.read(guideControllerProvider.notifier);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: step.canTapToAdvance ? () => controller.advance() : null,
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),

        if (guide.isSkippable)
          _buildSkipButton(context, ref),

        _buildProgressIndicator(context, guideState),

        CoachBubble(
          anchorId: step.anchorId,
          text: step.text,
          position: step.position,
          onTap: step.canTapToAdvance ? () => controller.advance() : null,
        ),
      ],
    );
  }


  Widget _buildSpotlightMode(
    BuildContext context,
    WidgetRef ref,
    GuideStep step,
    GuideState guideState,
    dynamic guide,
  ) {
    final controller = ref.read(guideControllerProvider.notifier);

    final content = Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (guide.isSkippable)
            _buildSkipButton(context, ref),

          _buildProgressIndicator(context, guideState),

          _buildPositionedDialogBox(
            context: context,
            step: step,
            isTypingCompleted: guideState.isTypingCompleted,
            hasHighlight: true,
            controller: controller,
            onTap: () => controller.advance(),
          ),
        ],
      ),
    );

    return SpotlightMask(
      anchorId: step.anchorId,
      onBlockedTap: step.canTapToAdvance
          ? () => controller.advance()
          : () {
              LockedFeatureOverlay.show(
                context,
                customTitle: 'Tap Highlight',
                customDescription:
                    'Please tap the highlighted area on the screen to proceed.',
                customConditionText: 'Tap Highlighted Area',
                customEmoji: '💡',
              );
            },
      child: content,
    );
  }


  Widget _buildActionMode(
    BuildContext context,
    WidgetRef ref,
    GuideStep step,
    GuideState guideState,
    dynamic guide,
  ) {
    final content = Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (guide.isSkippable)
            _buildSkipButton(context, ref),

          _buildProgressIndicator(context, guideState),

          Positioned(
            top: MediaQuery.paddingOf(context).top + 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFB).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF111111), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFD0C8C0), offset: Offset(4, 4)),
                ],
              ),
              child: Text(
                step.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E1100),
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.15, end: 0, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );

    if (step.anchorId != null) {
      return SpotlightMask(
        anchorId: step.anchorId,
        onBlockedTap: () {},
        child: content,
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        content,
      ],
    );
  }


  Widget _buildPortrait(GuideStep step) {
    String? assetPath;
    if (step.customPortraitAsset != null) {
      assetPath = step.customPortraitAsset;
    } else if (step.speakerCharacterId != null) {
      assetPath = GuideAssets.portraitPath(step.speakerCharacterId!);
    }

    if (assetPath == null) return const SizedBox.shrink();

    Alignment align = Alignment.bottomCenter;
    double beginSlideX = 0.0;
    if (step.speakerPosition == GuideSpeakerPosition.left) {
      align = Alignment.bottomLeft;
      beginSlideX = -0.3;
    } else if (step.speakerPosition == GuideSpeakerPosition.right) {
      align = Alignment.bottomRight;
      beginSlideX = 0.3;
    }

    return Align(
      alignment: align,
      child: FractionallySizedBox(
        widthFactor: 0.6,
        heightFactor: 0.75,
        child: Container(
          key: ValueKey(
              step.id + (step.speakerCharacterId ?? step.speakerName ?? '')),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            alignment: align,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 350.ms)
          .slideX(
              begin: beginSlideX,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutQuad),
    );
  }

  Widget _buildDialogBox(
    GuideStep step,
    bool isTypingCompleted,
    bool hasHighlight,
    GuideController controller,
  ) {
    Color accentColor = const Color(0xFF00E5FF);
    if (step.speakerCharacterId == 'arthur') {
      accentColor = const Color(0xFFFFD600);
    } else if (step.speakerCharacterId == 'lilith') {
      accentColor = const Color(0xFF8B5CF6);
    }

    return DoodleDialogBox(
      speakerName: step.speakerName ?? 'Guide',
      speakerAccentColor: accentColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: TypewriterText(
              text: step.text,
              key: ValueKey(step.id),
              showAll: isTypingCompleted,
              onCompleted: () => controller.setTypingCompleted(true),
            ),
          ),
          if (isTypingCompleted && !hasHighlight)
            Positioned(
              right: 0,
              bottom: 0,
              child: const Icon(
                Icons.arrow_right,
                size: 28,
                color: Color(0xFF111111),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 400.ms)
                  .then()
                  .fadeOut(duration: 400.ms),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, duration: 350.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSkipButton(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 16,
      right: 16,
      child: ComicButton(
        label: 'SKIP',
        style: PBStyle.dark,
        fontSize: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () => ref.read(guideControllerProvider.notifier).skip(),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, GuideState guideState) {
    final guide = guideState.activeGuide;
    if (guide == null || guide.steps.length <= 1) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${guideState.currentStepIndex + 1}/${guide.steps.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: 'Bangers',
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
