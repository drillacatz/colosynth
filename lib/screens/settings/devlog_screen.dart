import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:colosynth/screens/theme/background.dart';

class DevlogScreen extends StatelessWidget {
  const DevlogScreen({super.key});

  static const List<_DevlogEntry> _entries = [
    _DevlogEntry(
      version: 'v0.5.3',
      date: '08/09/2026',
      title: 'Performance & Engine Upgrade',
      highlights: [
        'Google Play August 2026 memory management & 16 KB page size support',
        'AppMemoryManager with proactive background memory trimming',
        'Comprehensive codebase performance & memory leak optimizations',
        'Modernized core dependencies & engine stability updates',
      ],
    ),
    _DevlogEntry(
      version: 'v0.4.0',
      date: '11/06/2026',
      title: 'story mode &tutorial ',
      highlights: [
        'Story Mode',
        'Tutorial restrict and highlight added',
        'Endless Battle UI polished',
        'Intrstitial ads added',
        'Google Play games progress sync added',
      ],
    ),
    _DevlogEntry(
      version: 'v0.3.0',
      date: '11/06/2026',
      title: 'game details added',
      highlights: [
        'New Character screen - customize synths & view stats',
        'Equipment upgrade system — spend Ink to strengthen your loadout',
        'Synth slot system — attach power modules to your synth',
        'Character roulette wheel',
        'Settings screen redesign with About, Support & Stats sections',
        'Level-gated feature ',
        'Daily tasks',
        'Performance improvements across all screens',
      ],
    ),
    _DevlogEntry(
      version: 'v0.2.0',
      date: '15/05/2026',
      title: 'Minor Fixes',
      highlights: [
        'Fixed a crash when returning to arena from tournament screen',
        'Google Sign-In flow now handles cancellation gracefully',
        'XP overflow bug at max level resolved',
        'Ink reward amounts rebalanced for early-game players',
        'Minor UI polish on bottom navigation bar',
      ],
    ),
    _DevlogEntry(
      version: 'v0.1.0',
      date: '01/05/2026',
      title: 'Initial Release',
      highlights: [
        'Basic battle system',
        'AI opponents',
        'Tournament brackets',
        'Ink & Paint economy',
        'Google Sign-In with cloud save progress',
        'Guest mode with local save support',
        'Endless Battle mode concept',
        'Level progression system',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A1A), size: 18),
        ),
        title: const Text(
          'DEVLOG',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0E0E0)),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: NotebookBackground()),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            itemCount: _entries.length,
            itemBuilder: (context, i) {
              return _EntryCard(entry: _entries[i])
                  .animate(delay: Duration(milliseconds: 60 * i))
                  .fadeIn(duration: 260.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
            },
          ),
        ],
      ),
    );
  }
}

class _DevlogEntry {
  const _DevlogEntry({
    required this.version,
    required this.date,
    required this.title,
    required this.highlights,
  });

  final String version;
  final String date;
  final String title;
  final List<String> highlights;
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final _DevlogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  entry.version,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  entry.date,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              entry.title,
              style: const TextStyle(
                color: Color(0xFF444444),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entry.highlights
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: SizedBox(
                              width: 5,
                              height: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF1A1A1A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              h,
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 12,
                                height: 1.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
