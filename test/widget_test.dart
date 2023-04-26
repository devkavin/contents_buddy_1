import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:contents_buddy_1/main.dart';

void main() {
  testWidgets('Test contact form', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap the floating action button to open the contact form
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Enter a name into the name field
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'John');

    // Enter a phone number into the phone field
    await tester.enterText(
        find.widgetWithText(TextField, 'Phone'), '1234567890');

    // Enter an email into the email field
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'john@example.com');

    // Tap the submit button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create New'));
    await tester.pumpAndSettle();

    // Expect to see the new contact in the list
    expect(find.widgetWithText(Text, 'John'), findsOneWidget);
    expect(find.widgetWithText(Text, '1234567890'), findsOneWidget);
    expect(find.widgetWithText(Text, 'john@example.com'), findsOneWidget);
  });
}
