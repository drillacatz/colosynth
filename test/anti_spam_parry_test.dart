import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/database/character/battle_stats.dart';
import 'package:colosynth/game/ai/ai_profiles.dart';
import 'package:colosynth/game/app_shell/battle_game.dart';
import 'package:colosynth/game/event_bus/game_events.dart';
import 'package:colosynth/game/logic/battle_state_machine.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game/logic/battle_constants.dart';

final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (message) async => _kTransparentPng.buffer.asByteData(),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  BattleFlameGame createGame() {
    return BattleFlameGame(
      playerStats: const BattleStats(
        atk: 50,
        def: 20,
        hp: 500,
        shield: 0,
        stamina: 100,
        speed: 10,
      ),
      characterId: 'arthur',
      equippedSynths: const [],
      aiProfile: AiProfile.easy(),
      tier: 1,
      slotId: 't1_1',
      mode: BattleMode.tournament,
    );
  }

  void advanceTime(BattleFlameGame game, double seconds) {
    const step = 1.0 / 60.0;
    var remaining = seconds;
    while (remaining > 0) {
      final dt = remaining > step ? step : remaining;
      game.update(dt);
      remaining -= dt;
    }
  }

  group('Anti-Spam Parry Combat Mechanics', () {
    late BattleFlameGame game;

    setUp(() async {
      game = createGame();
      game.onGameResize(Vector2(800, 600));
      await game.onLoad();
      // ignore: invalid_use_of_internal_member
      game.mount();
    });

    tearDown(() {
      game.onRemove();
    });

    test('initializes with zero spam count and false recoil', () {
      expect(game.idleAttackSpamCount, equals(0));
      expect(game.isAntiSpamRecoil, isFalse);
      expect(game.fsm.current, equals(BattleState.idle));
    });

    test('first two slashes land normally without parry', () {
      // Slash 1
      game.onPlayerSwipe(AttackDirection.n);
      expect(game.idleAttackSpamCount, equals(1));
      expect(game.fsm.current, equals(BattleState.playerSlash));
      expect(game.isAntiSpamRecoil, isFalse);

      // Advance through slash duration and return to idle
      advanceTime(game, BattleTimings.slashBriefDuration + 0.02);
      expect(game.fsm.current, equals(BattleState.enemyHurt));
      advanceTime(game, BattleTimings.hurtDuration + 0.02);
      expect(game.fsm.current, equals(BattleState.idle));

      // Slash 2
      game.onPlayerSwipe(AttackDirection.e);
      expect(game.idleAttackSpamCount, equals(2));
      expect(game.fsm.current, equals(BattleState.playerSlash));
      expect(game.isAntiSpamRecoil, isFalse);
    });

    test('fourth slash against idle enemy guarantees parry and enters blockedRecoil', () {
      // Set counter to 3 directly to isolate 4th guaranteed hit
      game.idleAttackSpamCount = 3;

      final initialEnemyHp = game.enemy.currentHp;

      // 4th attack triggers 100% parry
      game.onPlayerSwipe(AttackDirection.w);

      expect(game.idleAttackSpamCount, equals(0));
      expect(game.isAntiSpamRecoil, isTrue);
      expect(game.fsm.current, equals(BattleState.blockedRecoil));
      // Zero damage dealt on parry
      expect(game.enemy.currentHp, equals(initialEnemyHp));
    });

    test('blockedRecoil prevents player actions and transitions to enemyTelegraph on expiration', () {
      // Trigger parry
      game.idleAttackSpamCount = 3;
      game.onPlayerSwipe(AttackDirection.s);
      expect(game.fsm.current, equals(BattleState.blockedRecoil));
      expect(game.isAntiSpamRecoil, isTrue);

      // Player cannot swipe/slash during recoil
      game.onPlayerSwipe(AttackDirection.n);
      expect(game.fsm.current, equals(BattleState.blockedRecoil));

      // Player cannot dodge during recoil
      game.onPlayerDodge(isLeft: true);
      expect(game.fsm.current, equals(BattleState.blockedRecoil));

      // Player cannot block during recoil
      game.onPlayerBlockStart();
      expect(game.player.isGuarding, isFalse);

      // Advance time by blockedRecoilDuration (0.4s)
      advanceTime(game, BattleTimings.blockedRecoilDuration + 0.05);

      // Recoil expiration immediately triggers aggressive enemy counter telegraph
      expect(game.fsm.current, equals(BattleState.enemyTelegraph));
      expect(game.isAntiSpamRecoil, isFalse);
      expect(game.idleAttackSpamCount, equals(0));
    });

    test('idle spam counter decays after 1.5 seconds of inactivity', () {
      // Hit 2 times
      game.onPlayerSwipe(AttackDirection.n);
      expect(game.idleAttackSpamCount, equals(1));

      // Let 1.0s pass (not yet decayed)
      advanceTime(game, 1.0);
      expect(game.idleAttackSpamCount, equals(1));

      // Let another 0.6s pass (total 1.6s > 1.5s decay window)
      advanceTime(game, 0.6);
      expect(game.idleAttackSpamCount, equals(0));
    });

    test('resetBattle and revive reset anti-spam state cleanly', () {
      game.idleAttackSpamCount = 3;
      game.resetBattle();
      expect(game.idleAttackSpamCount, equals(0));
      expect(game.isAntiSpamRecoil, isFalse);

      game.idleAttackSpamCount = 2;
      game.revive();
      expect(game.idleAttackSpamCount, equals(0));
      expect(game.isAntiSpamRecoil, isFalse);
    });

    test('enemy guard shield drops on inactivity decay and telegraph transition', () {
      // Simulate enemy entering guard
      game.enemy.restoreStamina(100);
      // Manually trigger 3 hits to guarantee/escalate guard
      for (int i = 0; i < 3; i++) {
        game.onPlayerSwipe(AttackDirection.n);
        advanceTime(game, BattleTimings.slashBriefDuration + BattleTimings.hurtDuration + 0.05);
      }
      expect(game.enemy.isGuarding, isTrue);

      // Inactivity decay drops the guard shield
      advanceTime(game, 1.6);
      expect(game.idleAttackSpamCount, equals(0));
      expect(game.enemy.isGuarding, isFalse);
    });
  });
}
