import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/game_data/tournament_stage_data.dart';
import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/services/security_guard.dart';
import 'package:colosynth/services/achievement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Round 6 Economy Optimization Tests', () {
    test('120-Stage Paint rewards total exactly 1,200 Paint across all tiers', () {
      final stages = buildLinearTournamentStages();
      expect(stages.length, equals(120));

      final totalPaint = stages.fold<int>(0, (sum, stage) => sum + stage.paintReward);
      expect(totalPaint, equals(1200));

      // Verify Tier subtotals match design expectations
      final expectedTierSubtotals = [12, 36, 60, 84, 108, 132, 156, 180, 204, 228];
      for (int tier = 1; tier <= 10; tier++) {
        final tierStages = stages.where((s) => s.tier == tier);
        final tierPaint = tierStages.fold<int>(0, (sum, s) => sum + s.paintReward);
        expect(tierPaint, equals(expectedTierSubtotals[tier - 1]),
            reason: 'Tier $tier Paint subtotal mismatched');
      }
    });

    test('SecurityGuard permits all Round 6 award sources and spend reasons', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final guard = SecurityGuard.instance;
      await guard.init(prefs);

      final validRound6Sources = [
        'daily_first_win',
        'iap:ink_3000',
        'iap:ink_5000',
        'iap:ink_20000',
        'iap:ink_50000',
        'iap:ink_100000',
        'iap:ink_200000',
        'iap:ink_12000',
        'iap:ink_70000',
        'iap:ink_160000',
        'iap:ink_380000',
        'iap:ink_1100000',
        'iap:ink_2500000',
        'iap:paint_60',
        'iap:paint_180',
        'iap:paint_360',
        'iap:paint_500',
        'iap:paint_1200',
        'iap:paint_15',
        'iap:paint_85',
        'iap:paint_190',
        'iap:paint_420',
        'iap:paint_1150',
        'iap:paint_2500',
        'iap:combo_gearup',
        'iap:combo_deep',
        'iap:starter_bundle',
      ];

      for (final src in validRound6Sources) {
        expect(() => guard.validateAwardSource(src), returnsNormally,
            reason: 'SecurityGuard rejected valid source: $src');
      }

      expect(() => guard.validateSpendReason('synth_key_purchase'), returnsNormally);
    });

    test('StoreData bundles match standardized tiers and rebalanced values', () {
      expect(StoreData.inkBundles.length, equals(6));
      expect(StoreData.inkBundles.map((b) => b.ink).toList(),
          equals([12000, 70000, 160000, 380000, 1100000, 2500000]));
      expect(StoreData.inkBundles.map((b) => b.usdFallback).toList(),
          equals([r'$0.99', r'$4.99', r'$9.99', r'$19.99', r'$49.99', r'$99.99']));

      expect(StoreData.paintBundles.length, equals(6));
      expect(StoreData.paintBundles.map((b) => b.paint).toList(),
          equals([15, 85, 190, 420, 1150, 2500]));
      expect(StoreData.paintBundles.map((b) => b.usdFallback).toList(),
          equals([r'$0.99', r'$4.99', r'$9.99', r'$19.99', r'$49.99', r'$99.99']));

      // Verify rebalanced exp item bundles (all quantity 1)
      for (final bundle in StoreData.expItemBundles) {
        expect(bundle.quantity, equals(1),
            reason: 'Bundle ${bundle.id} quantity should be 1');
      }

      // Check specific item pricing
      final mythicBook = StoreData.expItemBundles.firstWhere((b) => b.id == 'exp_book_legendary');
      expect(mythicBook.usePaint, isTrue);
      expect(mythicBook.cost, equals(15));

      final godHammer = StoreData.expItemBundles.firstWhere((b) => b.id == 'exp_hammer_legendary');
      expect(godHammer.usePaint, isTrue);
      expect(godHammer.cost, equals(12));

      final mythicNote = StoreData.expItemBundles.firstWhere((b) => b.id == 'exp_note_legendary');
      expect(mythicNote.usePaint, isTrue);
      expect(mythicNote.cost, equals(10));
    });

    test('10-Tier clear achievements award total 44,000 Ink and 200 Paint', () {
      final tierIds = [
        AchievementIds.tournamentT1,
        AchievementIds.tournamentT2,
        AchievementIds.tournamentT3,
        AchievementIds.tournamentT4,
        AchievementIds.tournamentT5,
        AchievementIds.tournamentT6,
        AchievementIds.tournamentT7,
        AchievementIds.tournamentT8,
        AchievementIds.tournamentT9,
        AchievementIds.tournamentT10,
      ];

      int totalInk = 0;
      int totalPaint = 0;

      for (final id in tierIds) {
        final reward = AchievementRewards.all[id];
        expect(reward, isNotNull, reason: 'Missing reward for $id');
        totalInk += reward!.ink;
        totalPaint += reward.paint;
      }

      expect(totalInk, equals(44000));
      expect(totalPaint, equals(200));
    });
  });
}
