import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'providers/livret_a_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/screens.dart';
import 'theme/app_theme.dart';
import 'widgets/api_future_builder_loader.dart';

void main() async {
  // S'assure que les bindings Flutter et les canaux natifs sont initialisés
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Firebase.initializeApp();

  runApp(
    // Englobe toute l'application dans un ProviderScope Riverpod
    const ProviderScope(child: LivretAApp()),
  );
}

class NoStretchScrollBehavior extends ScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class LivretAApp extends ConsumerWidget {
  const LivretAApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Ouverture Livret A - Riverpod Sync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      scrollBehavior: const NoStretchScrollBehavior(),
      home: const AuthGate(),
    );
  }
}

/// Écran intermédiaire qui écoute les changements d'état d'authentification Firebase.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si l'utilisateur est authentifié, on redirige vers le parcours principal
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return ApiFutureBuilderLoader(
            key: ValueKey(user.uid),
            child: const MainNavigationFlow(),
          );
        }

        // Sinon, on affiche la page d'authentification initialement
        return const AuthScreen();
      },
    );
  }
}

/// Démonstrateur interactif du parcours de 5 pages utilisant Riverpod.
class MainNavigationFlow extends ConsumerStatefulWidget {
  const MainNavigationFlow({super.key});

  @override
  ConsumerState<MainNavigationFlow> createState() => _MainNavigationFlowState();
}

class _MainNavigationFlowState extends ConsumerState<MainNavigationFlow> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livretAProvider);

    // Synchronisation de l'étape du PageController avec l'état Riverpod
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != state.currentStep) {
        _pageController.animateToPage(
          state.currentStep,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ProductSelectionScreen(
            onSelectProduct: () => _goToStep(1),
          ),
          EligibilityScreen(
            onNext: () => _goToStep(2),
            onBack: () => _goToStep(0),
          ),
          UserInfoScreen(
            onNext: () => _goToStep(3),
            onBack: () => _goToStep(1),
          ),
          TransferScreen(
            onNext: () => _goToStep(4),
            onBack: () => _goToStep(2),
          ),
          SummaryScreen(
            onConfirm: () => _goToStep(5),
            onBack: () => _goToStep(3),
          ),
          SuccessScreen(onReset: () => _goToStep(0)),
        ],
      ),
    );
  }
}
