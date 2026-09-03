import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eligibilite_livret_a/main.dart';

void main() {
  testWidgets('App starts on step 1 eligibility screen with Riverpod', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationFlow(),
        ),
      ),
    );

    expect(find.text("Éligibilité Livret A"), findsOneWidget);
  });
}
