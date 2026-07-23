import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dev_assistant/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots and renders shell', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify shell renders
    expect(find.text('Flutter Dev Assistant'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);

    // Navigate to Project Scan
    await tester.tap(find.text('Project Scan'));
    await tester.pumpAndSettle();
    
    // We can't easily mock the file picker in an integration test, 
    // but we can assert the UI responds correctly
    expect(find.text('Select Flutter Project'), findsOneWidget);
  });
}
