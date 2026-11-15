import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watad/data/repository.dart';
import 'package:watad/main.dart';
import 'package:watad/state/app_state.dart';

Future<void> pumpApp(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(await Repository.open());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(WatadApp(state: state, googleFonts: false));
  await tester.pump();
}

void main() {
  testWidgets('phone / outer screen: bottom bar, Arabic home', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('ستريك المسجد'), findsOneWidget);
    expect(find.text('صلوات اليوم'), findsOneWidget);
  });

  testWidgets('Duo / Fold8 outer screen (466 wide) stays one column', (tester) async {
    await pumpApp(tester, const Size(466, 678));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('Duo / Fold8 inner screen (890 wide) uses the side rail', (tester) async {
    await pumpApp(tester, const Size(890, 626));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('calendar and settings open', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await tester.tap(find.text('التقويم').last);
    await tester.pump();
    expect(find.text('سبت'), findsOneWidget);
    await tester.tap(find.text('الإعدادات').last);
    await tester.pump();
    expect(find.text('الأعذار', skipOffstage: false), findsOneWidget);
    expect(find.text('التنبيهات والأذان'), findsOneWidget);
  });
}
