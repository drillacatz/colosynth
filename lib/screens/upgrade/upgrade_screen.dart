import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/screens/upgrade/upgrade_skill_tree_view.dart';
import 'package:colosynth/services/account_sync_service.dart';
import 'package:colosynth/guide/guide_anchor.dart';

export 'upgrade_screen_logic.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  @override
  void dispose() {
    unawaited(AccountSyncService.instance.flushMilestone());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 62),
        _TopBar(),
        Expanded(
          child: GuideAnchor(
            id: 'upgrade_skill_tree',
            child: SkillTreeView(),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.account_tree,
            color: Color(0xFF1A1A1A),
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            'SKILL TREE',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Bangers',
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
