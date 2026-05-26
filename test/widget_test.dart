import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/main.dart'; // Ensure it points to quran_app

void main() {
  testWidgets('Quran App Launch Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranApp());
    // Basic test
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
