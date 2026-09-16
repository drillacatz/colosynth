import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class FeedbackFaqScreen extends StatefulWidget {
  const FeedbackFaqScreen({super.key});

  @override
  State<FeedbackFaqScreen> createState() => _FeedbackFaqScreenState();
}

class _FeedbackFaqScreenState extends State<FeedbackFaqScreen> {
  final _controller = TextEditingController();
  bool _submitted = false;
  bool _submitting = false;

  static const _ink = Color(0xFF1A1A1A);
  static const _sub = Color(0xFF888888);
  static const _gold = _ink;
  static const _dim = Color(0xFFCCCCCC);

  static const _faqs = [
    (
      q: 'How do I earn Ink and Paint?',
      a: 'Win arena battles to earn resources. Completing daily tasks also grants bonus Ink and Paint each day.',
    ),
    (
      q: 'What unlocks at higher levels?',
      a: 'New tabs and modes unlock as you level up — Recruit, Character, and Endless Battle all become available as you progress through the ranks.',
    ),
    (
      q: 'What is Endless Battle mode?',
      a: 'Endless Battle is a roguelike mode unlocked at Level 5. Fight wave after wave of opponents and see how far your synth can survive.',
    ),
    (
      q: 'How does the XP and level system work?',
      a: 'You earn XP by winning battles. Your level progress is shown in the top-left pill on the home screen. Each new level can unlock features or rewards.',
    ),
    (
      q: 'Can I play without an internet connection?',
      a: 'Core arena gameplay works offline. Cloud saves, leaderboards, and daily reward sync require an active internet connection.',
    ),
    (
      q: 'How do I recover my progress on a new device?',
      a: 'Sign in with Google in the More tab. Your progress is tied to your Google account and will be restored automatically on any device.',
    ),
    (
      q: 'What are Daily Tasks?',
      a: 'Daily Tasks are challenges that refresh every 24 hours. Complete them to earn bonus Ink, Paint, and XP. They become available at Level 2.',
    ),
    (
      q: 'How do I report a bug?',
      a: 'Use the feedback form above. Describe the issue in as much detail as possible — device model, what you were doing, and what went wrong. We read every submission.',
    ),
  ];

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const Positioned.fill(child: NotebookBackground()),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader('FEEDBACK', Icons.edit_outlined),
                          const SizedBox(height: 10),
                          _buildFeedbackCard(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('FAQ', Icons.help_outline),
                          const SizedBox(height: 10),
                          _buildFaqCard(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                ComicButton.playButtonSfx();
                Navigator.pop(context);
              },
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.arrow_back_ios_new, color: _ink, size: 18),
              ),
            ),
          ),
          const Text(
            'FEEDBACK',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontFamily: 'Bangers',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _ink, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _sub,
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFD0D0D0), thickness: 1)),
      ],
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ink, width: 1.5),
      ),
      child: _submitted ? _buildThankYou() : _buildForm(),
    );
  }

  Widget _buildThankYou() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.check_circle_outline, color: _gold, size: 36),
        const SizedBox(height: 12),
        const Text(
          'THANK YOU!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontFamily: 'Bangers',
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your feedback has been received.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _sub, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _submitted = false),
          child: const Text(
            'Send another message',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _sub,
              fontSize: 11,
              decoration: TextDecoration.underline,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Questions, suggestions, or bug reports? We read everything.',
          style: TextStyle(color: _sub, fontSize: 12, height: 1.55),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          maxLines: 4,
          maxLength: 500,
          style: const TextStyle(color: _ink, fontSize: 13, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Write your message here...',
            hintStyle: const TextStyle(color: _dim, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _dim),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _dim),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _ink, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
            counterStyle: const TextStyle(color: _dim, fontSize: 10),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _submitting ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 46,
            decoration: BoxDecoration(
              color: _submitting ? const Color(0xFFCCCCCC) : _ink,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'SUBMIT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Bangers',
                        letterSpacing: 3,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ink, width: 1.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _faqs.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE8E8E8),
                indent: 16,
                endIndent: 16,
              ),
            _FaqTile(q: _faqs[i].q, a: _faqs[i].a),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.q, required this.a});
  final String q;
  final String a;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expand;

  static const _ink = Color(0xFF1A1A1A);
  static const _sub = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    ComicButton.playButtonSfx();
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.q,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: _sub,
                    size: 20,
                  ),
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _expand,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 4),
                child: Text(
                  widget.a,
                  style: const TextStyle(
                    color: _sub,
                    fontSize: 12,
                    height: 1.65,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
