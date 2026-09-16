import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/providers/navigation_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class ItemDetailsOverlay extends ConsumerWidget {
  const ItemDetailsOverlay({
    super.key,
    required this.itemId,
    required this.onClose,
  });

  final String itemId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = itemId.replaceAll('_', ' ').toUpperCase();
    final desc = 'Equipment piece for $itemId';
    const icon = Icons.shield;

    final levels = ref.watch(equipmentLevelsProvider);
    final level = levels[itemId]?.level ?? 0;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), offset: Offset(6, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.sketchGray.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.sketchGray),
                    ),
                    child: const Icon(icon, color: AppColors.sketchGray),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'LEVEL $level',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                desc,
                style: TextStyle(color: Colors.grey[800], fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () {
                    onClose();
                    ref.read(navigationProvider.notifier).selectTab(1);
                  },
                  child: const Text(
                    'GO TO UPGRADE',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Bangers',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
