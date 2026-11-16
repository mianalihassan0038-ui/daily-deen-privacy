import 'package:dailydeen/app_state.dart';
import 'package:dailydeen/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppState> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DailyDeenApp(state: state));
    await tester.pump();
    return state;
  }

  testWidgets('Home shows greeting, next prayer and checklist', (tester) async {
    await pumpApp(tester);
    expect(find.text('Assalamu Alaikum!'), findsOneWidget);
    expect(find.text('NEXT PRAYER'), findsOneWidget);
    expect(find.byKey(const Key('routine_wudu')), findsOneWidget);
  });

  testWidgets('Tapping a routine item marks it done', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('routine_wudu')));
    await tester.pump();
    expect(state.day(state.today).done.contains('wudu'), isTrue);
  });

  testWidgets('All tabs open without errors', (tester) async {
    await pumpApp(tester);
    for (final label in ['Namaz', 'Quran', 'Tasbeeh', 'Progress', 'Home']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tasbeeh counter increments', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.text('Tasbeeh').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tasbeeh_tap')));
    await tester.pump();
    expect(state.day(state.today).dhikr['subhanallah'], 1);
  });

  testWidgets('Quran plus button adds a page', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.text('Quran').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quran_plus')));
    await tester.pump();
    expect(state.day(state.today).quranPages, 1);
  });

  testWidgets('Switching to Urdu works and is RTL', (tester) async {
    final state = await pumpApp(tester);
    state.settings.urdu = true;
    state.saveSettings();
    await tester.pumpAndSettle();
    expect(find.text('السلام علیکم!'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.text('السلام علیکم!')));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('Settings screen opens', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Language'), findsOneWidget);
  });
}
