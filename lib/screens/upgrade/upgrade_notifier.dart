import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/providers/save_provider.dart';

class UpgradeState {
  const UpgradeState({this.selectedSlotIndex = 0});

  final int selectedSlotIndex;

  UpgradeState copyWith({int? selectedSlotIndex}) => UpgradeState(
        selectedSlotIndex: selectedSlotIndex ?? this.selectedSlotIndex,
      );
}

class UpgradeNotifier extends Notifier<UpgradeState> {
  @override
  UpgradeState build() => const UpgradeState();

  void selectSlot(int index) =>
      state = state.copyWith(selectedSlotIndex: index);

  Future<void> unlockSkillNode(
    String id,
    int inkCost,
    Set<String> prerequisites,
  ) async {
    await ref
        .read(skillTreeProvider.notifier)
        .unlock(id, inkCost, prerequisites);
  }

  Future<void> resetSkillTree() async {
    await ref.read(skillTreeProvider.notifier).reset();
  }
}

final upgradeNotifierProvider =
    NotifierProvider<UpgradeNotifier, UpgradeState>(UpgradeNotifier.new);
