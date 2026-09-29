import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kora_ai/app.dart';
import 'package:kora_ai/data/db/app_database.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() {
    AppDatabase.instance.useDatabasePath(inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kora_ai.settings.v1': jsonEncode(<String, Object?>{
        'baseUrl': 'https://saved.example.com/v1',
        'apiKey': 'sk-saved',
        'chatModel': 'saved-model',
        'embeddingModel': 'saved-embed',
        'systemPrompt': 'Saved prompt',
        'temperature': 0.2,
        'topK': 3,
        'useVectorSearch': false,
        'localeCode': null,
      }),
    });
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  testWidgets('shows the stored settings instead of the defaults',
      (tester) async {
    await _bootIntoSettings(tester);

    expect(find.text('https://saved.example.com/v1'), findsOneWidget);
    expect(find.text('saved-model'), findsOneWidget);
    expect(find.text('saved-embed'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Saved prompt'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Saved prompt'), findsOneWidget);
  });

  testWidgets('editing one field keeps the stored values for the others',
      (tester) async {
    await _bootIntoSettings(tester);

    // Index 1 is the API key field.
    await tester.enterText(find.byType(TextField).at(1), 'sk-updated');
    await tester.pump(const Duration(milliseconds: 700));

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('kora_ai.settings.v1');
    expect(raw, isNotNull);
    final saved = jsonDecode(raw!) as Map<String, Object?>;
    expect(saved['apiKey'], 'sk-updated');
    expect(saved['baseUrl'], 'https://saved.example.com/v1');
    expect(saved['chatModel'], 'saved-model');
    expect(saved['embeddingModel'], 'saved-embed');
    expect(saved['systemPrompt'], 'Saved prompt');
  });
}

Future<void> _bootIntoSettings(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const KoraAiApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(find.byIcon(Icons.settings_outlined).last);
  await tester.pumpAndSettle();
}
