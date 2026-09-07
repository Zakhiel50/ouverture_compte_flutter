import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eligibilite_livret_a/widgets/step_progress_bar.dart';

void main() {
  group('StepProgressBar Widget Tests', () {
    testWidgets('Affichage par défaut (étape 1 sur 5 = 20%)', (
      WidgetTester tester,
    ) async {
      // 1. Charger le widget dans l'environnement de test
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StepProgressBar(
              currentStep: 1,
              title: "Informations personnelles",
            ),
          ),
        ),
      );

      // 2. Vérifier les textes affichés
      expect(find.text('Étape 1 sur 5'), findsOneWidget);
      expect(find.text('20% complété'), findsOneWidget);
      expect(find.text('Informations personnelles'), findsOneWidget);

      // 3. Inspecter la valeur numérique de la jauge de progression
      final LinearProgressIndicator indicator = tester.widget(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, equals(0.2));
    });

    testWidgets(
      'Affichage avec nombre total d\'étapes personnalisé (étape 1 sur 4 = 25%)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StepProgressBar(
                currentStep: 1,
                totalSteps: 4,
                title: "Choix du produit",
              ),
            ),
          ),
        );

        // Vérification pour 1/4 = 25%
        expect(find.text('Étape 1 sur 4'), findsOneWidget);
        expect(find.text('25% complété'), findsOneWidget);
        expect(find.text('Choix du produit'), findsOneWidget);

        final LinearProgressIndicator indicator = tester.widget(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, equals(0.25));
      },
    );
  });
}
