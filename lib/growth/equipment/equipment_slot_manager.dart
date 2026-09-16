class EquipmentSlotManager {
  static Map<String, String> equip(Map<String, String> currentGear, String slot, String instanceId) {
    final newGear = Map<String, String>.from(currentGear);
    newGear[slot] = instanceId;
    return newGear;
  }

  static Map<String, String> unequip(Map<String, String> currentGear, String slot) {
    final newGear = Map<String, String>.from(currentGear);
    newGear.remove(slot);
    return newGear;
  }


  static Map<String, String> gearSetFor(Map<String, String> currentGear) {
    return currentGear;
  }
}
