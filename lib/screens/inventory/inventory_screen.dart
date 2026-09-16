import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/guide/guide_anchor.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/upgrade/upgrade_inventory_view.dart';
import 'package:colosynth/services/account_sync_service.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  void dispose() {
    unawaited(AccountSyncService.instance.flushMilestone());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned.fill(child: NotebookBackground()),
        Column(
          children: [
            SizedBox(height: 62),
            Expanded(
              child: GuideAnchor(
                id: 'upgrade_inventory',
                child: InventoryView(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
