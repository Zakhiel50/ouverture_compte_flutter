import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eligibilite_livret_a/widgets/theme_toggle_button.dart';
import 'package:eligibilite_livret_a/providers/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeToggleButton Widget Tests', () {
    testWidgets('Basculement de thème avec ThemeToggleButton standard', (WidgetTester tester) async {
      ThemeMode? currentTheme;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              currentTheme = ref.watch(themeModeProvider);
              return MaterialApp(
                themeMode: currentTheme,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                home: Scaffold(
                  appBar: AppBar(
                    actions: const [ThemeToggleButton()],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // 1. État initial : Mode clair par défaut
      expect(currentTheme, equals(ThemeMode.light));
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_rounded), findsNothing);
      expect(find.byTooltip("Basculer en Mode Sombre"), findsOneWidget);

      // 2. Clic sur le bouton de thème
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // 3. Vérification du passage en Mode Sombre
      expect(currentTheme, equals(ThemeMode.dark));
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_rounded), findsNothing);
      expect(find.byTooltip("Basculer en Mode Clair"), findsOneWidget);

      // 4. Second clic pour revenir en Mode Clair
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // 5. Vérification du retour en Mode Clair
      expect(currentTheme, equals(ThemeMode.light));
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_rounded), findsNothing);
    });

    testWidgets('Basculement de thème avec ThemeToggleButton.labeled', (WidgetTester tester) async {
      ThemeMode? currentTheme;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              currentTheme = ref.watch(themeModeProvider);
              return MaterialApp(
                themeMode: currentTheme,
                home: const Scaffold(
                  body: Center(
                    child: ThemeToggleButton.labeled(),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // 1. État initial
      expect(currentTheme, equals(ThemeMode.light));
      expect(find.text("Mode Sombre"), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

      // 2. Clic sur le bouton nommé (via son libellé)
      await tester.tap(find.text("Mode Sombre"));
      await tester.pumpAndSettle();

      // 3. Passage au mode sombre (libellé devient "Mode Clair")
      expect(currentTheme, equals(ThemeMode.dark));
      expect(find.text("Mode Clair"), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

      // 4. Clic à nouveau
      await tester.tap(find.text("Mode Clair"));
      await tester.pumpAndSettle();

      // 5. Reconstitution du mode clair
      expect(currentTheme, equals(ThemeMode.light));
      expect(find.text("Mode Sombre"), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    });
  });
}
