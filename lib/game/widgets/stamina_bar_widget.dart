import 'package:flutter/material.dart';
import 'package:colosynth/game/logic/stamina_system.dart';

class StaminaBarWidget extends StatelessWidget {
  const StaminaBarWidget({super.key, required this.staminaSystem});

  final StaminaSystem staminaSystem;

  static const _kHudStamina = Color(0xFF4488DD);
  static const _kHudBarBg = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: staminaSystem.notifier,
      builder: (_, __, ___) {
        final ratio = staminaSystem.ratio;
        return Row(
          children: [
            const Text(
              'STM',
              style: TextStyle(
                fontFamily: 'Bangers',
                color: _kHudStamina,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _kHudBarBg,
                  border: Border.all(color: Colors.black87, width: 1),
                ),
                clipBehavior: Clip.hardEdge,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(color: _kHudStamina),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
