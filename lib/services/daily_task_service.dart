import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:colosynth/utils/date_utils.dart';
import 'package:colosynth/utils/async_mutex.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';

@immutable
class DailyTask {
  const DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.activityPoints,
    required this.paintReward,
    required this.inkReward,
  });

  final String id;
  final String title;
  final String description;
  final int target;
  final int activityPoints;
  final int paintReward;
  final int inkReward;
}

class DailyTaskService extends ChangeNotifier {
  DailyTaskService._();
  static final DailyTaskService instance = DailyTaskService._();

  Ref? _ref;

  static const String _kPoolTasks = 'daily_pool_tasks';
  static const String _kPoolProgress = 'daily_pool_progress';
  static const String _kPoolClaimed = 'daily_pool_claimed';
  static const String _kPoolDate = 'daily_pool_date';
  static const String _kWeeklyPoints = 'weekly_activity_points';
  static const String _kWeeklyWeek = 'weekly_activity_week';
  static const String _kWeekly400Claimed = 'weekly_milestone_400_claimed';
  static const String _kWeekly800Claimed = 'weekly_milestone_800_claimed';
  static const String _kDailyFirstWinDate = 'daily_first_win_date';

  bool _dailyFirstWinClaimedToday = false;
  bool get dailyFirstWinClaimedToday => _dailyFirstWinClaimedToday;

  static const List<DailyTask> fixedTasks = [
    DailyTask(
      id: 'battle_1',
      title: 'FIRST STRIKE',
      description: 'Win 1 battle',
      target: 1,
      activityPoints: 25,
      paintReward: 0,
      inkReward: 500,
    ),
    DailyTask(
      id: 'claim_daily_ink',
      title: 'DAILY GIFT',
      description: 'Claim daily free gift',
      target: 1,
      activityPoints: 10,
      paintReward: 0,
      inkReward: 0,
    ),
    DailyTask(
      id: 'battle_3',
      title: 'SYNTH BRAWLER',
      description: 'Win 3 battles',
      target: 3,
      activityPoints: 15,
      paintReward: 0,
      inkReward: 800,
    ),
  ];

  static const List<DailyTask> poolRegistry = [
    DailyTask(
        id: 'pool_parry_1',
        title: 'PARRY I',
        description: 'Parry 1 time',
        target: 1,
        activityPoints: 5,
        paintReward: 2,
        inkReward: 100),
    DailyTask(
        id: 'pool_parry_3',
        title: 'PARRY II',
        description: 'Parry 3 times',
        target: 3,
        activityPoints: 15,
        paintReward: 2,
        inkReward: 300),
    DailyTask(
        id: 'pool_parry_5',
        title: 'PARRY III',
        description: 'Parry 5 times',
        target: 5,
        activityPoints: 20,
        paintReward: 2,
        inkReward: 400),
    DailyTask(
        id: 'pool_parry_10',
        title: 'PARRY IV',
        description: 'Parry 10 times',
        target: 10,
        activityPoints: 40,
        paintReward: 2,
        inkReward: 800),
    DailyTask(
        id: 'pool_skill_2',
        title: 'SKILL I',
        description: 'Use skill 2 times',
        target: 2,
        activityPoints: 10,
        paintReward: 2,
        inkReward: 200),
    DailyTask(
        id: 'pool_skill_5',
        title: 'SKILL II',
        description: 'Use skill 5 times',
        target: 5,
        activityPoints: 20,
        paintReward: 2,
        inkReward: 400),
    DailyTask(
        id: 'pool_skill_8',
        title: 'SKILL III',
        description: 'Use skill 8 times',
        target: 8,
        activityPoints: 35,
        paintReward: 2,
        inkReward: 700),
    DailyTask(
        id: 'pool_dodge_3',
        title: 'DODGE I',
        description: 'Dodge 3 times',
        target: 3,
        activityPoints: 10,
        paintReward: 2,
        inkReward: 200),
    DailyTask(
        id: 'pool_dodge_5',
        title: 'DODGE II',
        description: 'Dodge 5 times',
        target: 5,
        activityPoints: 20,
        paintReward: 2,
        inkReward: 400),
    DailyTask(
        id: 'pool_dodge_10',
        title: 'DODGE III',
        description: 'Dodge 10 times',
        target: 10,
        activityPoints: 30,
        paintReward: 2,
        inkReward: 600),
    DailyTask(
        id: 'pool_win_1',
        title: 'WIN I',
        description: 'Win 1 battle',
        target: 1,
        activityPoints: 10,
        paintReward: 2,
        inkReward: 200),
    DailyTask(
        id: 'pool_win_3',
        title: 'WIN II',
        description: 'Win 3 battles',
        target: 3,
        activityPoints: 20,
        paintReward: 2,
        inkReward: 400),
    DailyTask(
        id: 'pool_win_5',
        title: 'WIN III',
        description: 'Win 5 battles',
        target: 5,
        activityPoints: 30,
        paintReward: 2,
        inkReward: 600),
    DailyTask(
        id: 'pool_upgrade_equip_1',
        title: 'FORGE I',
        description: 'Upgrade equipment 1 time',
        target: 1,
        activityPoints: 10,
        paintReward: 2,
        inkReward: 200),
    DailyTask(
        id: 'pool_upgrade_equip_3',
        title: 'FORGE II',
        description: 'Upgrade equipment 3 times',
        target: 3,
        activityPoints: 25,
        paintReward: 2,
        inkReward: 500),
    DailyTask(
        id: 'pool_upgrade_equip_5',
        title: 'FORGE III',
        description: 'Upgrade equipment 5 times',
        target: 5,
        activityPoints: 40,
        paintReward: 2,
        inkReward: 800),
    DailyTask(
        id: 'pool_upgrade_char_1',
        title: 'TRAIN I',
        description: 'Use exp item 1 time',
        target: 1,
        activityPoints: 10,
        paintReward: 2,
        inkReward: 200),
    DailyTask(
        id: 'pool_upgrade_char_3',
        title: 'TRAIN II',
        description: 'Use exp item 3 times',
        target: 3,
        activityPoints: 25,
        paintReward: 2,
        inkReward: 500),
    DailyTask(
        id: 'pool_upgrade_char_5',
        title: 'TRAIN III',
        description: 'Use exp item 5 times',
        target: 5,
        activityPoints: 40,
        paintReward: 2,
        inkReward: 800),
  ];

  static const List<List<String>> validCombinations = [
    [
      'pool_parry_10',
      'pool_skill_8',
      'pool_dodge_10',
      'pool_win_3',
      'pool_upgrade_equip_3'
    ],
    [
      'pool_parry_10',
      'pool_skill_8',
      'pool_dodge_5',
      'pool_win_5',
      'pool_upgrade_char_3'
    ],
    [
      'pool_parry_10',
      'pool_skill_5',
      'pool_dodge_10',
      'pool_win_3',
      'pool_upgrade_equip_5'
    ],
    [
      'pool_parry_10',
      'pool_skill_2',
      'pool_dodge_10',
      'pool_win_5',
      'pool_upgrade_char_5'
    ],
    [
      'pool_parry_3',
      'pool_skill_8',
      'pool_dodge_10',
      'pool_win_5',
      'pool_upgrade_equip_5'
    ],
    [
      'pool_parry_3',
      'pool_skill_8',
      'pool_dodge_10',
      'pool_win_5',
      'pool_upgrade_char_5'
    ],
  ];

  final Map<String, int> _taskProgress = {};
  final Map<String, bool> _taskClaimed = {};
  final List<DailyTask> _activePoolTasks = [];
  final Map<String, int> _poolProgress = {};
  final Map<String, bool> _poolClaimed = {};

  int _activity = 0;
  int _weeklyPoints = 0;
  bool _milestone400Claimed = false;
  bool _milestone800Claimed = false;
  bool _initialized = false;
  SharedPreferences? _prefs;
  final AsyncMutex _writeMutex = AsyncMutex();

  List<DailyTask>? _cachedMergedTasks;
  final Map<String, DailyTask> _tasksLookup = {};

  int get activity => _activity;
  int get weeklyPoints => _weeklyPoints;
  bool get milestone400Claimed => _milestone400Claimed;
  bool get milestone800Claimed => _milestone800Claimed;
  List<DailyTask> get activePoolTasks => _activePoolTasks;
  bool get initialized => _initialized;

  static const int activityDisplayMax = 100;
  static const List<int> milestoneThresholds = [30, 60, 100];
  static const Map<int, Map<String, dynamic>> milestones = {
    30: {'item': 'exp_hammer_common'},
    60: {'item': 'exp_book_common'},
    100: {'paint': 5, 'item': 'exp_book_common', 'xp': 500},
  };

  static List<DailyTask> get tasks {
    if (instance._cachedMergedTasks == null) {
      instance._updateCachedTasks();
    }
    return instance._cachedMergedTasks!;
  }

  void _updateCachedTasks() {
    _cachedMergedTasks = [...fixedTasks, ..._activePoolTasks];
    _tasksLookup.clear();
    for (final t in _cachedMergedTasks!) {
      _tasksLookup[t.id] = t;
    }
  }

  int get displayActivity => min(_activity, activityDisplayMax);

  bool isMilestoneReached(int threshold) => _activity >= threshold;
  bool isMilestoneClaimed(int threshold) =>
      _taskClaimed['activity_$threshold'] ?? false;

  bool get hasAnyClaimable {
    for (final task in fixedTasks.followedBy(_activePoolTasks)) {
      if (isCompleted(task.id) && !isClaimed(task.id)) return true;
    }

    if (_activity >= 30 && !(_taskClaimed['activity_30'] ?? false)) return true;
    if (_activity >= 60 && !(_taskClaimed['activity_60'] ?? false)) return true;
    if (_activity >= 100 && !(_taskClaimed['activity_100'] ?? false)) {
      return true;
    }

    if (_weeklyPoints >= 400 && !_milestone400Claimed) return true;
    if (_weeklyPoints >= 800 && !_milestone800Claimed) return true;

    return false;
  }

  bool isCompleted(String taskId) {
    if (taskId == 'activity_30') return _activity >= 30;
    if (taskId == 'activity_60') return _activity >= 60;
    if (taskId == 'activity_100') return _activity >= 100;

    if (_tasksLookup.isEmpty) {
      _updateCachedTasks();
    }
    final task = _tasksLookup[taskId] ??
        const DailyTask(
            id: 'null',
            title: '',
            description: '',
            target: 999999,
            activityPoints: 0,
            paintReward: 0,
            inkReward: 0);

    final target =
        (taskId == 'battle_5' && SaveManager.instance.loadAccountLevel() >= 99)
            ? 3
            : task.target;
    return getProgress(taskId) >= target;
  }

  int getProgress(String taskId) {
    if (taskId.startsWith('pool_')) return _poolProgress[taskId] ?? 0;
    return _taskProgress[taskId] ?? 0;
  }

  bool isClaimed(String taskId) {
    if (taskId.startsWith('pool_')) return _poolClaimed[taskId] ?? false;
    return _taskClaimed[taskId] ?? false;
  }

  final List<StreamSubscription> _subscriptions = [];

  Future<void> checkAndGrantDailyFirstWin() async {
    _prefs ??= await SharedPreferences.getInstance();
    final today = AppDateUtils.todayKey();
    final claimedDate = _prefs!.getString(_kDailyFirstWinDate);
    if (claimedDate != today) {
      await _prefs!.setString(_kDailyFirstWinDate, today);
      _dailyFirstWinClaimedToday = true;
      try {
        await SaveManager.instance.account.awardPaint(5, source: 'daily_first_win');
      } catch (e) {
        AppLogger.e('DailyTaskService', 'Failed to award daily first win paint: $e');
      }
      notifyListeners();
    }
  }

  void _subscribeToEvents() {
    if (_subscriptions.isNotEmpty) return;

    _subscriptions.add(GameEventBus.instance.on<VictoryEvent>().listen((event) {
      if (event.mode == BattleMode.tournament) {
        checkAndGrantDailyFirstWin();
        notifyAction('tournament_clear');
      }
      notifyAction('battle_win');
    }));
    _subscriptions
        .add(GameEventBus.instance.on<ParrySuccessEvent>().listen((_) {
      notifyAction('parry');
    }));
    _subscriptions
        .add(GameEventBus.instance.on<DodgeSuccessEvent>().listen((_) {
      notifyAction('dodge');
    }));
    _subscriptions
        .add(GameEventBus.instance.on<ActiveSkillReleasedEvent>().listen((_) {
      notifyAction('skill_use');
    }));
    _subscriptions
        .add(GameEventBus.instance.on<EquipmentUpgradedEvent>().listen((_) {
      notifyAction('upgrade_equip');
    }));
    _subscriptions
        .add(GameEventBus.instance.on<ExpItemConsumedEvent>().listen((_) {
      notifyAction('use_exp_item');
    }));
    _subscriptions
        .add(GameEventBus.instance.on<DailyGiftClaimedEvent>().listen((_) {
      notifyAction('claim_daily_ink');
    }));
    _subscriptions.add(
        GameEventBus.instance.on<ExtremeRotationClearedEvent>().listen((_) {
      notifyAction('tournament_clear');
    }));
  }

  Future<void> init([SharedPreferences? prefs]) async {
    if (_initialized) return;
    if (prefs != null) {
      _prefs = prefs;
    }
    await _load();
    _subscribeToEvents();
    _initialized = true;
    notifyListeners();
  }

  Future<void> reload() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();

    _taskProgress.clear();
    _taskClaimed.clear();
    _activePoolTasks.clear();
    _poolProgress.clear();
    _poolClaimed.clear();
    _activity = 0;
    _weeklyPoints = 0;
    _milestone400Claimed = false;
    _milestone800Claimed = false;
    _initialized = false;
    _cachedMergedTasks = null;
    _tasksLookup.clear();
    await init();
  }

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    final today = AppDateUtils.todayKey();
    final week = AppDateUtils.weekKey();

    if (prefs.getString(_kPoolDate) != today) {
      await _resetDaily(prefs, today);
    } else {
      _loadDaily(prefs);
    }

    if (prefs.getString(_kWeeklyWeek) != week) {
      await _resetWeekly(prefs, week);
    } else {
      _loadWeekly(prefs);
    }

    notifyListeners();
  }

  Future<void> _resetDaily(SharedPreferences prefs, String date) async {
    _activity = 0;
    _taskProgress.clear();
    _taskClaimed.clear();
    _poolProgress.clear();
    _poolClaimed.clear();
    _dailyFirstWinClaimedToday = false;

    final combo = validCombinations[
        Random(date.hashCode).nextInt(validCombinations.length)];
    _activePoolTasks.clear();
    for (final id in combo) {
      _activePoolTasks.add(poolRegistry.firstWhere((t) => t.id == id));
    }

    await prefs.setString(_kPoolDate, date);
    await prefs.setStringList(_kPoolTasks, combo);
    _updateCachedTasks();
    await _persistDaily(prefs);
  }

  void _loadDaily(SharedPreferences prefs) {
    _activity = prefs.getInt('daily_activity') ?? 0;
    final today = AppDateUtils.todayKey();
    _dailyFirstWinClaimedToday = prefs.getString(_kDailyFirstWinDate) == today;

    final combo = prefs.getStringList(_kPoolTasks) ?? [];
    _activePoolTasks.clear();
    for (final id in combo) {
      _activePoolTasks.add(poolRegistry.firstWhere((t) => t.id == id));
    }

    final rawProg = prefs.getString('daily_task_prog');
    if (rawProg != null) {
      _taskProgress.addAll(Map<String, int>.from(jsonDecode(rawProg)));
    }

    final rawClaimed = prefs.getString('daily_task_claimed');
    if (rawClaimed != null) {
      _taskClaimed.addAll(Map<String, bool>.from(jsonDecode(rawClaimed)));
    }

    final rawPoolProg = prefs.getString(_kPoolProgress);
    if (rawPoolProg != null) {
      _poolProgress.addAll(Map<String, int>.from(jsonDecode(rawPoolProg)));
    }

    final rawPoolClaimed = prefs.getString(_kPoolClaimed);
    if (rawPoolClaimed != null) {
      _poolClaimed.addAll(Map<String, bool>.from(jsonDecode(rawPoolClaimed)));
    }

    _updateCachedTasks();
  }

  Future<void> _resetWeekly(SharedPreferences prefs, String week) async {
    _weeklyPoints = 0;
    _milestone400Claimed = false;
    _milestone800Claimed = false;
    await prefs.setString(_kWeeklyWeek, week);
    await _persistWeekly(prefs);
  }

  void _loadWeekly(SharedPreferences prefs) {
    _weeklyPoints = prefs.getInt(_kWeeklyPoints) ?? 0;
    _milestone400Claimed = prefs.getBool(_kWeekly400Claimed) ?? false;
    _milestone800Claimed = prefs.getBool(_kWeekly800Claimed) ?? false;
  }

  Future<void> _persistDaily(SharedPreferences prefs) async {
    await prefs.setInt('daily_activity', _activity);
    await prefs.setString('daily_task_prog', jsonEncode(_taskProgress));
    await prefs.setString('daily_task_claimed', jsonEncode(_taskClaimed));
    await prefs.setString(_kPoolProgress, jsonEncode(_poolProgress));
    await prefs.setString(_kPoolClaimed, jsonEncode(_poolClaimed));
  }

  Future<void> _persistWeekly(SharedPreferences prefs) async {
    await prefs.setInt(_kWeeklyPoints, _weeklyPoints);
    await prefs.setBool(_kWeekly400Claimed, _milestone400Claimed);
    await prefs.setBool(_kWeekly800Claimed, _milestone800Claimed);
  }

  Future<void> recordProgress(String taskId, {int amount = 1}) async {
    final task = fixedTasks.followedBy(_activePoolTasks).firstWhere(
        (t) => t.id == taskId,
        orElse: () => DailyTask(
            id: taskId,
            title: '',
            description: '',
            target: 999,
            activityPoints: 0,
            paintReward: 0,
            inkReward: 0));
    final isPool = taskId.startsWith('pool_');
    final cur =
        isPool ? (_poolProgress[taskId] ?? 0) : (_taskProgress[taskId] ?? 0);
    if (cur >= task.target) return;
    final next = (cur + amount).clamp(0, task.target);
    if (isPool) {
      _poolProgress[taskId] = next;
      if (next == task.target) {
        await _grantRandomPoolReward();
      }
    } else {
      _taskProgress[taskId] = next;
    }
  }

  Future<void> notifyAction(String actionType, {int amount = 1}) async {
    await _writeMutex.protect(() async {
      for (final task in fixedTasks) {
        if (_matchesAction(task.id, actionType)) {
          await recordProgress(task.id, amount: amount);
        }
      }

      for (final task in _activePoolTasks) {
        if (_matchesAction(task.id, actionType)) {
          final cur = _poolProgress[task.id] ?? 0;
          if (cur < task.target) {
            final next = (cur + amount).clamp(0, task.target);
            _poolProgress[task.id] = next;
            if (next == task.target) {
              await _grantRandomPoolReward();
            }
          }
        }
      }

      _prefs ??= await SharedPreferences.getInstance();
      await _persistDaily(_prefs!);
      notifyListeners();
    });
  }

  bool _matchesAction(String taskId, String actionType) {
    if (taskId == 'battle_1' || taskId == 'battle_3' || taskId == 'battle_5') {
      return actionType == 'battle_win';
    }
    if (taskId.contains('parry')) return actionType == 'parry';
    if (taskId.contains('skill')) return actionType == 'skill_use';
    if (taskId.contains('dodge')) return actionType == 'dodge';
    if (taskId.contains('win')) return actionType == 'battle_win';
    if (taskId.contains('upgrade_equip')) return actionType == 'upgrade_equip';
    if (taskId.contains('upgrade_char')) return actionType == 'use_exp_item';

    return taskId == actionType;
  }

  Future<void> _grantRandomPoolReward() async {
    if (_activity >= 250) return;

    if (_ref == null) return;
    try {
      final roll = Random().nextDouble();
      if (roll < 0.50) {
        await _ref!
            .read(walletProvider.notifier)
            .award(Currency.ink, 150, source: 'daily_task');
      } else if (roll < 0.80) {
        await _ref!
            .read(walletProvider.notifier)
            .award(Currency.ink, 300, source: 'daily_task');
      } else if (roll < 0.95) {
        await _ref!
            .read(walletProvider.notifier)
            .award(Currency.ink, 500, source: 'daily_task');
      } else {
        await _ref!
            .read(walletProvider.notifier)
            .award(Currency.paint, 1, source: 'daily_task');
      }
    } catch (e) {
      AppLogger.w('DailyTaskService', 'Could not grant pool reward: $e');
    }
  }

  Future<void> claimTask(String taskId) async {
    await _writeMutex.protect(() async {
      if (isClaimed(taskId) || !isCompleted(taskId)) return;

      if (_tasksLookup.isEmpty) _updateCachedTasks();
      if (!_tasksLookup.containsKey(taskId)) return;
      final task = _tasksLookup[taskId]!;

      if (taskId.startsWith('pool_')) {
        _poolClaimed[taskId] = true;
      } else {
        _taskClaimed[taskId] = true;
      }

      _activity = (_activity + task.activityPoints).clamp(0, 250);
      _weeklyPoints += task.activityPoints;

      if (task.inkReward > 0 || task.paintReward > 0) {
        if (_ref != null) {
          await _ref!.read(walletProvider.notifier).awardMultiple(
                ink: task.inkReward,
                paint: task.paintReward,
                source: 'daily_task',
              );
        }
      }

      _prefs ??= await SharedPreferences.getInstance();
      await _persistDaily(_prefs!);
      await _persistWeekly(_prefs!);
      notifyListeners();
    });
  }

  Future<void> claimMilestone(int threshold) async {
    await _writeMutex.protect(() async {
      if (!isMilestoneReached(threshold) || isMilestoneClaimed(threshold)) {
        return;
      }

      _taskClaimed['activity_$threshold'] = true;

      final reward = milestones[threshold];
      if (reward != null) {
        final ink = (reward['ink'] as num?)?.toInt() ?? 0;
        final paint = (reward['paint'] as num?)?.toInt() ?? 0;
        if (ink > 0 || paint > 0) {
          if (_ref != null) {
            await _ref!.read(walletProvider.notifier).awardMultiple(
                  ink: ink,
                  paint: paint,
                  source: 'daily_milestone',
                );
          }
        }
        if (reward.containsKey('item')) {
          if (_ref != null) {
            await _ref!
                .read(expItemsProvider.notifier)
                .grant(reward['item'] as String, 1);
          }
        }
        if (reward.containsKey('xp') && (reward['xp'] as int) > 0) {
          if (_ref != null) {
            await _ref!
                .read(accountLevelProvider.notifier)
                .addXp(reward['xp'] as int);
          }
        }
      }

      _prefs ??= await SharedPreferences.getInstance();
      await _persistDaily(_prefs!);
      notifyListeners();
    });
  }

  Future<void> claimWeeklyMilestone(int threshold) async {
    await _writeMutex.protect(() async {
      if (_weeklyPoints < threshold) return;
      if (threshold == 400 && !_milestone400Claimed) {
        _milestone400Claimed = true;
        if (_ref != null) {
          await _ref!
              .read(walletProvider.notifier)
              .award(Currency.paint, 10, source: 'weekly_activity');
          await _ref!
              .read(expItemsProvider.notifier)
              .grant('exp_hammer_common', 3);
        }
      } else if (threshold == 800 && !_milestone800Claimed) {
        _milestone800Claimed = true;
        if (_ref != null) {
          await _ref!
              .read(walletProvider.notifier)
              .award(Currency.paint, 10, source: 'weekly_activity');
          await _ref!
              .read(expItemsProvider.notifier)
              .grant('exp_book_common', 2);
        }
      }
      _prefs ??= await SharedPreferences.getInstance();
      await _persistWeekly(_prefs!);
      notifyListeners();
    });
  }

  /// Claims all completed tasks, daily milestones, and weekly milestones.
  /// Returns the aggregated reward summary.
  Future<({int ink, int paint, int xp, Map<String, int> items})> claimAll() async {
    int totalInk = 0;
    int totalPaint = 0;
    int totalXp = 0;
    final Map<String, int> totalItems = {};

    // 1. Claim all completed tasks
    for (final task in tasks) {
      if (isCompleted(task.id) && !isClaimed(task.id)) {
        totalInk += task.inkReward;
        totalPaint += task.paintReward;
        await claimTask(task.id);
      }
    }

    // 2. Claim all reached daily milestones
    for (final threshold in milestoneThresholds) {
      if (isMilestoneReached(threshold) && !isMilestoneClaimed(threshold)) {
        final reward = milestones[threshold] ?? {};
        totalInk += (reward['ink'] as num?)?.toInt() ?? 0;
        totalPaint += (reward['paint'] as num?)?.toInt() ?? 0;
        totalXp += (reward['xp'] as num?)?.toInt() ?? 0;
        final item = reward['item'] as String?;
        if (item != null) {
          totalItems[item] = (totalItems[item] ?? 0) + 1;
        }
        await claimMilestone(threshold);
      }
    }

    // 3. Claim weekly milestones if reached
    if (_weeklyPoints >= 400 && !_milestone400Claimed) {
      totalPaint += 10;
      totalItems['exp_hammer_common'] = (totalItems['exp_hammer_common'] ?? 0) + 3;
      await claimWeeklyMilestone(400);
    }
    if (_weeklyPoints >= 800 && !_milestone800Claimed) {
      totalPaint += 10;
      totalItems['exp_book_common'] = (totalItems['exp_book_common'] ?? 0) + 2;
      await claimWeeklyMilestone(800);
    }

    return (ink: totalInk, paint: totalPaint, xp: totalXp, items: totalItems);
  }
}

final dailyTaskServiceProvider = Provider<DailyTaskService>((ref) {
  final service = DailyTaskService.instance;
  service._ref = ref;
  return service;
});

class DailyTaskNotifier extends Notifier<DailyTaskService> {
  @override
  DailyTaskService build() {
    final service = DailyTaskService.instance;
    service._ref = ref;
    if (!service.initialized) {
      unawaited(service.init());
    }
    void listener() {
      state = service;
    }
    service.addListener(listener);
    ref.onDispose(() => service.removeListener(listener));
    ref.keepAlive();
    return service;
  }
}

final dailyTaskNotifierProvider =
    NotifierProvider<DailyTaskNotifier, DailyTaskService>(
  DailyTaskNotifier.new,
);
