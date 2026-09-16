import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/services/daily_task_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyTaskService Logic & Milestone Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DailyTaskService.instance.reload();
    });

    test('Milestone thresholds are defined correctly', () {
      expect(DailyTaskService.milestoneThresholds, equals([30, 60, 100]));
      expect(DailyTaskService.milestones[30]?['item'], equals('exp_hammer_common'));
      expect(DailyTaskService.milestones[60]?['item'], equals('exp_book_common'));
      expect(DailyTaskService.milestones[100]?['paint'], equals(5));
      expect(DailyTaskService.milestones[100]?['xp'], equals(500));
    });

    test('Weekly milestones state initial and claim mechanics', () async {
      final service = DailyTaskService.instance;

      expect(service.weeklyPoints, equals(0));
      expect(service.milestone400Claimed, isFalse);
      expect(service.milestone800Claimed, isFalse);

      // Cannot claim if points below threshold
      await service.claimWeeklyMilestone(400);
      expect(service.milestone400Claimed, isFalse);
    });

    test('claimAll aggregates completed tasks and milestone rewards', () async {
      final service = DailyTaskService.instance;

      // Find first fixed task
      final task = DailyTaskService.tasks.first;
      // Record progress up to target
      await service.recordProgress(task.id, amount: task.target);
      expect(service.isCompleted(task.id), isTrue);
      expect(service.isClaimed(task.id), isFalse);

      final summary = await service.claimAll();
      expect(summary.ink, equals(task.inkReward));
      expect(summary.paint, equals(task.paintReward));
      expect(service.isClaimed(task.id), isTrue);
    });

    test('init with SharedPreferences sets initialized and notifies listeners', () async {
      final service = DailyTaskService.instance;
      final prefs = await SharedPreferences.getInstance();

      int notifications = 0;
      void listener() => notifications++;
      service.addListener(listener);

      // Force reload to uninitialized state
      await service.reload();
      expect(service.initialized, isTrue);

      // Re-init with explicit prefs
      await service.init(prefs);
      expect(service.initialized, isTrue);

      service.removeListener(listener);
      expect(notifications, greaterThanOrEqualTo(1));
    });
  });
}
