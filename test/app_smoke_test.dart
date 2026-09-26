import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kora_ai/app.dart';
import 'package:kora_ai/data/db/app_database.dart';

/// Boots the whole widget tree against an in-memory database.
///
/// This is the safety net for the parts unit tests cannot reach: provider
/// wiring, localisation, a real SQLite schema and the responsive shell.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    AppDatabase.instance.useDatabasePath(inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  testWidgets('boots into the chat tab', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KoraAiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Desktop width renders the navigation rail instead of a bottom bar.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('KoraAI'), findsWidgets);
  });

  testWidgets('narrow layout falls back to bottom navigation', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KoraAiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('switching to the documents tab works', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KoraAiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.description_outlined).last);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
