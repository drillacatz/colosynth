import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colosynth/growth/character/skills/skill_tree_module.dart';
import 'package:colosynth/providers/character_provider.dart';
import 'package:colosynth/screens/upgrade/upgrade_screen_logic.dart';
import 'package:colosynth/screens/upgrade/upgrade_skill_tree_view.dart';

void main() {
  group('Modernized Skill Tree Consistency Tests', () {
    test('kAllSkillNodes contains exactly 29 canonical nodes matching SkillTreeModule', () {
      expect(kAllSkillNodes.length, equals(29));

      // Category breakdown
      final offenseNodes = nodesForCategory(SkillCategory.offense);
      final defenseNodes = nodesForCategory(SkillCategory.defense);
      final utilityNodes = nodesForCategory(SkillCategory.utility);

      expect(offenseNodes.length, equals(9));
      expect(defenseNodes.length, equals(10));
      expect(utilityNodes.length, equals(10));
    });

    test('every UI node ID and ink cost strictly matches SkillTreeModule inkCostFor', () {
      for (final node in kAllSkillNodes) {
        final expectedCost = SkillTreeModule.inkCostFor(node.id);
        expect(
          node.inkCost,
          equals(expectedCost),
          reason: 'Node ${node.id} ink cost (${node.inkCost}) mismatched SkillTreeModule ($expectedCost)',
        );
      }
    });

    test('prerequisite graph has valid node references and zero circular dependencies', () {
      final allIds = kAllSkillNodes.map((n) => n.id).toSet();

      for (final node in kAllSkillNodes) {
        for (final prereq in node.prerequisites) {
          expect(
            allIds.contains(prereq),
            isTrue,
            reason: 'Prerequisite $prereq of node ${node.id} does not exist in kAllSkillNodes',
          );
        }
      }

      // Check for cycles by topological traversal
      final visited = <String>{};
      final visiting = <String>{};

      bool hasCycle(String id) {
        if (visiting.contains(id)) return true;
        if (visited.contains(id)) return false;

        visiting.add(id);
        final node = kAllSkillNodes.firstWhere((n) => n.id == id);
        for (final p in node.prerequisites) {
          if (hasCycle(p)) return true;
        }
        visiting.remove(id);
        visited.add(id);
        return false;
      }

      for (final node in kAllSkillNodes) {
        expect(hasCycle(node.id), isFalse, reason: 'Cycle detected involving ${node.id}');
      }
    });
  });

  group('SkillTreeView 3-Column Vertical Widget Tests', () {
    testWidgets('renders SkillTreeView across 3 columns without overflow on compact screen', (tester) async {
      tester.view.physicalSize = const Size(320, 568); // Compact iPhone SE
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            skillTreeProvider.overrideWith(SkillTreeNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SkillTreeView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no exceptions / overflow
      expect(tester.takeException(), isNull);

      // Verify 3 column headers are visible
      expect(find.text('OFFENSE'), findsOneWidget);
      expect(find.text('DEFENSE'), findsOneWidget);
      expect(find.text('UTILITY'), findsOneWidget);

      // Verify starter nodes are rendered
      expect(find.text('STRIKE I'), findsOneWidget);
      expect(find.text('VITALITY I'), findsOneWidget);
      expect(find.text('ENDURANCE I'), findsOneWidget);

      // Test vertical scrolling
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping an unlockable node opens the node detail modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            skillTreeProvider.overrideWith(SkillTreeNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SkillTreeView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap STRIKE I node
      await tester.tap(find.text('STRIKE I'));
      await tester.pumpAndSettle();

      // Verify dialog opened
      expect(find.text('STRIKE I'), findsNWidgets(2)); // On tree + in dialog
      expect(find.text('INK COST:'), findsOneWidget);
      expect(find.text('300 INK'), findsOneWidget);
    });
  });
}
