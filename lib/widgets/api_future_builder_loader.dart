import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/livret_a_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'custom_button.dart';

import '../services/firebase_auth_service.dart';

class ApiFutureBuilderLoader extends ConsumerStatefulWidget {
  final Widget child;

  const ApiFutureBuilderLoader({super.key, required this.child});

  @override
  ConsumerState<ApiFutureBuilderLoader> createState() =>
      _ApiFutureBuilderLoaderState();
}

class _ApiFutureBuilderLoaderState
    extends ConsumerState<ApiFutureBuilderLoader> {
  late Future<Map<String, dynamic>> _dataApi;

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  void _loadApiData() {
    setState(() {
      _dataApi = ApiService.fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataApi,
      builder: (context, snapshot) {
        // -------------------------------------------------------------
        // Condition 1 : SNAPSHOT WAITING (Chargement en cours)
        // -------------------------------------------------------------
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accent,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Connexion à l'API bancaire (Riverpod)...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Récupération des données utilisateur depuis l'API...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // -------------------------------------------------------------
        // Condition 2 : SNAPSHOT HAS ERROR (Gestion de l'erreur API)
        // -------------------------------------------------------------
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.error,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Une erreur s'est produite",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: "Réessayer",
                            icon: Icons.refresh_rounded,
                            onPressed: _loadApiData,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: AppTheme.error,
                        side: BorderSide(
                          color: AppTheme.error.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        "Se déconnecter",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        await AuthService().signOut();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        }

        // -------------------------------------------------------------
        // Condition 3 : SNAPSHOT HAS DATA (Données API reçues avec succès)
        // -------------------------------------------------------------
        if (snapshot.hasData) {
          final dataAPI = snapshot.data!;

          // Injection des données API dans le Provider Riverpod
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(livretAProvider.notifier).loadFromApiData(dataAPI);
          });

          return widget.child;
        }

        return widget.child;
      },
    );
  }
}
