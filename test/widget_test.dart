import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/providers/app_provider.dart';

import 'package:quran_app/main.dart';

void main() {
  testWidgets('Quran App Launch Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const QuranApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Basic test
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
