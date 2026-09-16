import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/story/models/story_node.dart';
import 'package:colosynth/story/story_controller.dart';
import 'package:colosynth/guide/guide_assets.dart';
import 'package:colosynth/guide/ui/doodle_dialog_box.dart';
import 'package:colosynth/guide/ui/typewriter_text.dart';
import 'package:colosynth/screens/theme/tokens.dart';

/// Presentation widget for narrative story cutscenes.
class StoryOverlay extends ConsumerWidget {
  const StoryOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyState = ref.watch(storyStateProvider);
    if (!storyState.isActive) return const SizedBox.shrink();

    final node = storyState.currentNode;
    if (node == null) return const SizedBox.shrink();

    final story = storyState.activeStory!;
    final notifier = ref.read(storyStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => notifier.advance(),
              child: const SizedBox.shrink(),
            ),
          ),

          Positioned.fill(
            bottom: 230,
            child: SafeArea(
              child: _buildPortrait(node),
            ),
          ),

          if (story.isSkippable)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              right: 16,
              child: ComicButton(
                label: 'SKIP',
                style: PBStyle.dark,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onTap: () => notifier.skip(),
              ),
            ),

          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            height: 180,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => notifier.advance(),
              child: _buildDialogBox(node, storyState.isTypingCompleted, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortrait(StoryNode node) {
    String? assetPath;
    if (node.customPortraitAsset != null) {
      assetPath = node.customPortraitAsset;
    } else if (node.speakerCharacterId != null) {
      assetPath = GuideAssets.portraitPath(node.speakerCharacterId!);
    }

    if (assetPath == null) return const SizedBox.shrink();

    Alignment align = Alignment.bottomCenter;
    double beginSlideX = 0.0;
    if (node.speakerPosition == StorySpeakerPosition.left) {
      align = Alignment.bottomLeft;
      beginSlideX = -0.3;
    } else if (node.speakerPosition == StorySpeakerPosition.right) {
      align = Alignment.bottomRight;
      beginSlideX = 0.3;
    }

    return Align(
      alignment: align,
      child: FractionallySizedBox(
        widthFactor: 0.6,
        heightFactor: 0.75,
        child: Container(
          key: ValueKey(node.id + (node.speakerCharacterId ?? node.speakerName)),
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
          .slideX(begin: beginSlideX, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildDialogBox(StoryNode node, bool isTypingCompleted, StoryNotifier notifier) {
    Color accentColor = const Color(0xFF00E5FF);
    if (node.speakerCharacterId == 'arthur') {
      accentColor = const Color(0xFFFFD600);
    } else if (node.speakerCharacterId == 'lilith') {
      accentColor = const Color(0xFF8B5CF6);
    }

    return DoodleDialogBox(
      speakerName: node.speakerName,
      speakerAccentColor: accentColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: TypewriterText(
              text: node.dialogueText,
              key: ValueKey(node.id),
              showAll: isTypingCompleted,
              onCompleted: () => notifier.setTypingCompleted(true),
            ),
          ),
          if (isTypingCompleted)
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
}
