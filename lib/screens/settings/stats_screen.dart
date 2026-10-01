import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/account_provider.dart';
import 'package:colosynth/services/battle_stats_service.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/theme/tokens.dart';

/// Dedicated standalone Stats Screen presenting player career metrics,
/// combat performance, win-rates, streak records, and tournament victories.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _kInk = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = BattleStatsService.instance;
    final totalBattles = stats.totalBattles;
    final wins = stats.totalWins;
    final losses = stats.totalLosses;
    final winRate = totalBattles > 0
        ? (wins / totalBattles * 100).toStringAsFixed(1)
        : '—';
    final currentStreak = stats.currentStreak;
    final bestStreak = stats.bestStreak;

    final levelData = ref.watch(accountLevelProvider);
    final totalXp = levelData.accountXp;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kInk, size: 18),
          onPressed: () {
            ComicButton.playButtonSfx();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'CAREER & STATS',
          style: TextStyle(
            color: _kInk,
            fontFamily: 'Bangers',
            fontSize: 22,
            letterSpacing: 2.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: _kInk, height: 1.5),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: NotebookBackground()),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Overview Card
                _HeroCareerCard(
                  totalBattles: totalBattles,
                  wins: wins,
                  losses: losses,
                  winRate: winRate,
                  currentStreak: currentStreak,
                  bestStreak: bestStreak,
                ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.06, end: 0),

                const SizedBox(height: 24),

                // 2. Battle Record Grid
                const _CategoryHeader(label: 'BATTLE RECORD', icon: Icons.sports_martial_arts),
                const SizedBox(height: 10),
                _StatGrid(
                  items: [
                    _StatTileData(
                      icon: Icons.sports_martial_arts,
                      label: 'TOTAL BATTLES',
                      value: '$totalBattles',
                    ),
                    _StatTileData(
                      icon: Icons.emoji_events_outlined,
                      label: 'VICTORIES',
                      value: '$wins',
                      valueColor: const Color(0xFF1A7A3A),
                    ),
                    _StatTileData(
                      icon: Icons.close_rounded,
                      label: 'DEFEATS',
                      value: '$losses',
                      valueColor: const Color(0xFFCC2222),
                    ),
                    _StatTileData(
                      icon: Icons.percent,
                      label: 'WIN RATE',
                      value: winRate == '—' ? '—' : '$winRate%',
                      valueColor: const Color(0xFF0077CC),
                    ),
                  ],
                ).animate(delay: 50.ms).fadeIn(duration: 220.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 20),

                // 3. Streak Metrics
                const _CategoryHeader(label: 'STREAKS & RESILIENCE', icon: Icons.local_fire_department_outlined),
                const SizedBox(height: 10),
                _StatGrid(
                  items: [
                    _StatTileData(
                      icon: Icons.local_fire_department_outlined,
                      label: 'CURRENT STREAK',
                      value: '$currentStreak',
                      valueColor: currentStreak > 0 ? const Color(0xFFE07000) : null,
                    ),
                    _StatTileData(
                      icon: Icons.military_tech_outlined,
                      label: 'BEST STREAK',
                      value: '$bestStreak',
                      valueColor: bestStreak >= 5 ? const Color(0xFFE07000) : null,
                    ),
                  ],
                ).animate(delay: 90.ms).fadeIn(duration: 220.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 20),

                // 4. Combat Performance
                const _CategoryHeader(label: 'COMBAT PERFORMANCE', icon: Icons.shield_outlined),
                const SizedBox(height: 10),
                _StatGrid(
                  items: [
                    _StatTileData(
                      icon: Icons.shield_outlined,
                      label: 'TOTAL PARRIES',
                      value: ProgressionService.fmtInk(stats.totalParries),
                      valueColor: const Color(0xFF0088AA),
                    ),
                    _StatTileData(
                      icon: Icons.gavel_rounded,
                      label: 'TOTAL BREAKS',
                      value: ProgressionService.fmtInk(stats.totalBroken),
                      valueColor: const Color(0xFF8844AA),
                    ),
                  ],
                ).animate(delay: 130.ms).fadeIn(duration: 220.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 20),

                // 5. Progression
                const _CategoryHeader(label: 'ACCOUNT PROGRESSION', icon: Icons.trending_up),
                const SizedBox(height: 10),
                _StatGrid(
                  items: [
                    _StatTileData(
                      icon: Icons.trending_up,
                      label: 'ACCOUNT LEVEL',
                      value: '${levelData.accountLevel}',
                    ),
                    _StatTileData(
                      icon: Icons.star_border_rounded,
                      label: 'TOTAL XP EARNED',
                      value: ProgressionService.fmtInk(totalXp.toInt()),
                    ),
                    _StatTileData(
                      icon: Icons.calendar_today_outlined,
                      label: 'CONSECUTIVE LOGINS',
                      value: '${stats.consecutiveLogins} DAYS',
                      valueColor: const Color(0xFF1A7A3A),
                    ),
                  ],
                ).animate(delay: 170.ms).fadeIn(duration: 220.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 20),

                // 6. Tournaments
                const _CategoryHeader(label: 'TOURNAMENT TROPHIES', icon: Icons.workspace_premium_outlined),
                const SizedBox(height: 10),
                _StatGrid(
                  items: [
                    _StatTileData(
                      icon: Icons.workspace_premium_outlined,
                      label: 'EASY WINS',
                      value: '${stats.tournamentWins('easy')}',
                    ),
                    _StatTileData(
                      icon: Icons.workspace_premium_outlined,
                      label: 'MEDIUM WINS',
                      value: '${stats.tournamentWins('medium')}',
                    ),
                    _StatTileData(
                      icon: Icons.workspace_premium_outlined,
                      label: 'HARD WINS',
                      value: '${stats.tournamentWins('hard')}',
                      valueColor: const Color(0xFFCC6600),
                    ),
                    _StatTileData(
                      icon: Icons.workspace_premium_outlined,
                      label: 'EXTREME WINS',
                      value: '${stats.tournamentWins('extreme')}',
                      valueColor: const Color(0xFFCC2222),
                    ),
                  ],
                ).animate(delay: 210.ms).fadeIn(duration: 220.ms).slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

class _HeroCareerCard extends StatelessWidget {
  const _HeroCareerCard({
    required this.totalBattles,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int totalBattles;
  final int wins;
  final int losses;
  final String winRate;
  final int currentStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final winFraction = totalBattles > 0 ? (wins / totalBattles).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1A1A1A),
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.comicYellow,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                ),
                child: const Text(
                  'CAREER OVERVIEW',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              if (currentStreak >= 3)
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5500), size: 18),
                    const SizedBox(width: 2),
                    Text(
                      '$currentStreak HOT STREAK',
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 12,
                        color: Color(0xFFFF5500),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WIN RATE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF888888),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    winRate == '—' ? '—' : '$winRate%',
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 32,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 1.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    _MiniBadge(label: 'WINS', value: '$wins', color: const Color(0xFF1A7A3A)),
                    _MiniBadge(label: 'LOSSES', value: '$losses', color: const Color(0xFFCC2222)),
                    _MiniBadge(label: 'STREAK', value: '$bestStreak', color: const Color(0xFFE07000)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Win/loss visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (winFraction * 100).round(),
                    child: Container(color: const Color(0xFF22AA55)),
                  ),
                  Expanded(
                    flex: ((1.0 - winFraction) * 100).round(),
                    child: Container(color: const Color(0xFFDD3333)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF888888),
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatTileData {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatTileData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<_StatTileData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 340 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 68,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1A1A1A),
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF1A1A1A), width: 1.2),
                    ),
                    child: Icon(item.icon, size: 18, color: const Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF888888),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 20,
                            letterSpacing: 1.2,
                            color: item.valueColor ?? const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
