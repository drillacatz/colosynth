import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/providers/store_provider.dart';
import 'package:colosynth/screens/theme/tokens.dart';

import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';

class RestorePurchaseButton extends ConsumerStatefulWidget {
  const RestorePurchaseButton({super.key});

  @override
  ConsumerState<RestorePurchaseButton> createState() =>
      _RestorePurchaseButtonState();
}

class _RestorePurchaseButtonState extends ConsumerState<RestorePurchaseButton> {
  bool _restoring = false;

  Future<void> _onRestore() async {
    if (_restoring) return;
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.lightImpact());
    setState(() => _restoring = true);

    try {
      await ref.read(storeControllerProvider).restorePurchases();
      if (mounted) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Purchases Restored',
          customDescription: 'Your previous purchases have been successfully restored.',
          customConditionText: 'Success',
          customEmoji: '✓',
        ));
      }
    } catch (e) {
      if (mounted) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Restore Failed',
          customDescription: 'Unable to restore purchases at this time. Please try again.',
          customConditionText: 'Error',
          customEmoji: '❌',
        ));
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _restoring ? null : _onRestore,
        child: AnimatedOpacity(
          opacity: _restoring ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFCCCCCC),
                width: 1,
              ),
            ),
            child: _restoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF888888),
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restore,
                        color: Color(0xFF888888),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'RESTORE PURCHASES',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
