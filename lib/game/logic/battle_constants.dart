abstract final class InputConstants {

  static const double swipeVelocityThreshold = 400.0;


  static const double minSwipeDistance = 80.0;



  static const double maxBufferTime = 0.15;
}




abstract final class BattleTimings {

  static const double minIdleSecs = 1.0;
  static const double maxIdleSecs = 2.0;


  static const double telegraphDuration = 1.6;


  static const double parryFlashDuration = 0.7;



  static const double slashBriefDuration = 0.12;


  static const double hurtDuration = 0.24;


  static const double dodgeStateDuration = 0.6;


  static const double enemyHitLeadIn = 0.12;


  static const double skillDuration = 0.85;


  static const double victorySlowMoScale = 0.15;


  static const int victoryResultDelayMs = 2000;


  static const int defeatResultDelayMs = 800;



  static const double slashCancelEarlyWindow = 0.05;



  static const double hurtCancelEarlyWindow = 0.12;
}





abstract final class StaminaConstants {

  static const int defaultMax = 100;


  static const double blockDrainPerSec = 15.0;


  static const double idleRestorePerSec = 10.0;


  static const int dodgeCost = 20;


  static const int dodgeMinRequired = 20;


  static const int hitRestoreAmount = 5;



  static const double enemyDodgeDrainRatio = 0.30;


  static const double enemyParryDrainRatio = 0.80;


  static const double enemyDefenseDrainRatio = 0.10;
}




abstract final class SkillMeterConstants {

  static const int maxCharge = 100;

  /// Spec §11.3: onHitNormal: +10
  static const int chargePerNormalHit = 10;

  /// Spec §11.3: onParry: +25
  static const int chargePerParry = 25;

  /// Spec §11.3: onDodge: +10
  static const int chargePerDodge = 10;

  /// Spec §11.3: onHurt: +5
  static const int chargeOnHurt = 5;

  /// Spec §11.3: onCounterSlash: +50
  static const int chargePerCounterSlash = 50;
}




abstract final class DamageConstants {
  static const double counterComboMult1 = 1.00;
  static const double counterComboMult2 = 1.15;
  static const double counterComboMult3 = 1.20;
  static const double counterComboMult4 = 1.35;
  static const double counterComboMult5 = 1.50;

  static const double activeSkillDamageMult = 1.0;
  static const double outOfStaggerDamageMult = 0.25;

  static const int minDamage = 0;
  static const int maxDamage = 0x7FFFFFFFFFFFFFFF;
}




abstract final class PlayerConstants {

  static const double spriteW = 90.0;
  static const double spriteH = 200.0;


  static const double startX = 240.0;
  static const double startY = 840.0;


  static const double dodgeDistance = 80.0;


  static const double dodgeDuration = 0.7;
}




abstract final class EnemyConstants {

  static const double spriteW = 46.0;
  static const double spriteH = 102.0;


  static const double startX = 240.0;
  static const double startY = 370.0;
}




abstract final class RewardConstants {

  static const double inkScoreDivisor = 8.0;
  static const int inkMinPerVictory = 20;
  static const int inkMaxPerVictory = 600;


  static const int comboScorePerHit = 100;


  static const double rewardHpThreshold = 0.33;
  static const double rewardMultFull = 1.0;
  static const double rewardMultLow = 0.5;


  static const int xpOnDefeat = 25;


  static const int xpTierMultiplier = 50;
  static const int xpVictoryBase = 100;
}









abstract final class ArenaConstants {

  static const double vpX = 240.0;
  static const double vpY = 260.0;


  static const double floorNearY = 920.0;
  static const double floorHalfW = 340.0;


  static const int gridHLines = 8;
}
