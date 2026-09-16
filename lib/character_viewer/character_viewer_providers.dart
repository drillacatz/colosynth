import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/services/sp_manager.dart';

/// Notifier for 3D Model auto-rotate setting.
class AutoRotate3dNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromSp();
    return true;
  }

  Future<void> _loadFromSp() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(SPKeys.settingsAutoRotate3d) ?? true;
  }

  Future<void> setAutoRotate(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SPKeys.settingsAutoRotate3d, enabled);
  }

  Future<void> toggle() async {
    await setAutoRotate(!state);
  }
}

final autoRotate3dProvider = NotifierProvider<AutoRotate3dNotifier, bool>(
  AutoRotate3dNotifier.new,
);

class CharacterAnimationNotifier extends Notifier<String> {
  final String characterId;
  CharacterAnimationNotifier(this.characterId);

  @override
  String build() => 'idle';

  @override
  set state(String val) => super.state = val;
  void setAnimation(String anim) => state = anim;
}

final characterAnimationProvider =
    NotifierProvider.family<CharacterAnimationNotifier, String, String>(
  CharacterAnimationNotifier.new,
);

class CharacterViewer3dModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  @override
  set state(bool val) => super.state = val;
  void toggle() => state = !state;
}

final characterViewer3dModeProvider =
    NotifierProvider<CharacterViewer3dModeNotifier, bool>(
  CharacterViewer3dModeNotifier.new,
);
