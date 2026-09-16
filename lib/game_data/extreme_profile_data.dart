import 'package:colosynth/game/ai/ai_profiles.dart';

class ExtremeProfileData {
  final int slotIndex;
  final int enemyHp;
  final int enemyAtk;
  final int enemyDef;
  final int enemyShield;
  final int enemyStamina;
  final AiProfile aiProfile;

  const ExtremeProfileData({
    required this.slotIndex,
    required this.enemyHp,
    required this.enemyAtk,
    required this.enemyDef,
    required this.enemyShield,
    this.enemyStamina = 250,
    required this.aiProfile,
  });
}

const AiProfile kExtremeAiProfile = AiProfile(
  id: 'extreme_rotation',
  telegraphDuration: 0.55,
  attackInterval: 1.0,
  blockProbability: 0.70,
  dodgeProbability: 0.40,
  comboProbability: 0.55,
  unblockableRate: 0.20,
  activeSkillEnabled: true,
  bpm: 140,
  staminaMax: 250,
);

final List<ExtremeProfileData> kExtremeProfiles = [
  const ExtremeProfileData(
    slotIndex: 1,
    enemyHp: 50000,
    enemyAtk: 5000,
    enemyDef: 600,
    enemyShield: 1000,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 2,
    enemyHp: 60000,
    enemyAtk: 5800,
    enemyDef: 690,
    enemyShield: 1180,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 3,
    enemyHp: 70000,
    enemyAtk: 6600,
    enemyDef: 780,
    enemyShield: 1360,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 4,
    enemyHp: 80000,
    enemyAtk: 7300,
    enemyDef: 870,
    enemyShield: 1530,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 5,
    enemyHp: 90000,
    enemyAtk: 8100,
    enemyDef: 960,
    enemyShield: 1710,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 6,
    enemyHp: 100000,
    enemyAtk: 8900,
    enemyDef: 1040,
    enemyShield: 1890,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 7,
    enemyHp: 110000,
    enemyAtk: 9700,
    enemyDef: 1130,
    enemyShield: 2070,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 8,
    enemyHp: 120000,
    enemyAtk: 10400,
    enemyDef: 1220,
    enemyShield: 2240,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 9,
    enemyHp: 130000,
    enemyAtk: 11200,
    enemyDef: 1310,
    enemyShield: 2420,
    aiProfile: kExtremeAiProfile,
  ),
  const ExtremeProfileData(
    slotIndex: 10,
    enemyHp: 140000,
    enemyAtk: 12000,
    enemyDef: 1400,
    enemyShield: 2600,
    aiProfile: kExtremeAiProfile,
  ),
];
