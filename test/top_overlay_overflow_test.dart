import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/screens/overlays/top_overlay.dart';
import 'package:colosynth/providers/save_provider.dart';

class _FakeAccountLevelNotifier extends AccountLevelNotifier {
  @override
  ({int accountLevel, int accountXp}) build() {
    return (accountLevel: 12, accountXp: 1850);
  }
}

class _FakeSynthKeysNotifier extends SynthKeysNotifier {
  @override
  int build() => 5;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTopOverlayHarness({required double width}) {
    return ProviderScope(
      overrides: [
        inkProvider.overrideWithValue(25400),
        paintProvider.overrideWithValue(350),
        synthKeysProvider.overrideWith(() => _FakeSynthKeysNotifier()),
        accountLevelProvider.overrideWith(() => _FakeAccountLevelNotifier()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 700),
            padding: const EdgeInsets.only(top: 24),
          ),
          child: const Scaffold(
            body: TopOverlay(visible: true),
          ),
        ),
      ),
    );
  }

  testWidgets('TopOverlay renders without pixel overflow on 340dp screen',
      (tester) async {
    tester.view.physicalSize = const Size(340, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTopOverlayHarness(width: 340));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TopOverlay), findsOneWidget);
    expect(find.byType(LevelExpChip), findsOneWidget);
    expect(find.byType(CurrencyPill), findsNWidgets(2));
    expect(find.byType(SynthKeyPill), findsOneWidget);
  });

  testWidgets('TopOverlay renders without pixel overflow on standard 360dp screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTopOverlayHarness(width: 360));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TopOverlay), findsOneWidget);
  });
}
