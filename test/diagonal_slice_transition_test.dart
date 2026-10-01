import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/widgets/transitions/diagonal_slice_route.dart';

void main() {
  group('DiagonalSlicePageRoute & DiagonalSliceTransition Tests', () {
    testWidgets('Renders child inside DiagonalSliceTransition', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 380),
      );
      final secController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagonalSliceTransition(
              animation: controller,
              secondaryAnimation: secController,
              child: const Text('Test Diagonal Screen'),
            ),
          ),
        ),
      );

      // At t=0, entrance animation is starting, text widget exists in tree
      expect(find.text('Test Diagonal Screen'), findsWidgets);

      // Move animation to t=0.5
      controller.value = 0.5;
      await tester.pump();
      expect(find.text('Test Diagonal Screen'), findsWidgets);

      // Move animation to completion (t=1.0)
      controller.value = 1.0;
      await tester.pump();
      // At completion and dismissed secondaryAnimation, fast-path renders single child
      expect(find.text('Test Diagonal Screen'), findsOneWidget);

      controller.dispose();
      secController.dispose();
    });

    testWidgets('DiagonalSlicePageRoute pushes and pops cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    DiagonalSlicePageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Text('Pushed Screen Content'),
                      ),
                    ),
                  );
                },
                child: const Text('Open Route'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Open Route'), findsOneWidget);
      expect(find.text('Pushed Screen Content'), findsNothing);

      // Tap button to push
      await tester.tap(find.text('Open Route'));
      await tester.pump(); // Start transition

      // Halfway through transition
      await tester.pump(const Duration(milliseconds: 190));
      expect(find.text('Pushed Screen Content'), findsWidgets);

      // Transition complete
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Pushed Screen Content'), findsOneWidget);

      // Pop the route
      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      navigatorState.pop();
      await tester.pump();

      // Halfway through exit
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Pushed Screen Content'), findsWidgets);

      // Exit complete
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.text('Pushed Screen Content'), findsNothing);
      expect(find.text('Open Route'), findsOneWidget);
    });

    testWidgets('Exiting secondaryAnimation triggers forward exit slide', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 380),
        value: 1.0,
      );
      final secController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagonalSliceTransition(
              animation: controller,
              secondaryAnimation: secController,
              child: const Text('Secondary Animation Test'),
            ),
          ),
        ),
      );

      // At secController = 0.0 (dismissed) and controller = 1.0 (completed) -> fast path single child
      expect(find.text('Secondary Animation Test'), findsOneWidget);

      // Start secondary animation (when a new route is pushed on top)
      secController.value = 0.5;
      await tester.pump();
      expect(find.text('Secondary Animation Test'), findsWidgets);

      controller.dispose();
      secController.dispose();
    });
  });
}
