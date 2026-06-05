import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mimo/main.dart';

void main() {
  testWidgets('App smoke test - renders DashboardScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title 'Control' is present.
    expect(find.text('Control'), findsOneWidget);
  });
}
