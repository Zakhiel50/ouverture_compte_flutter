import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/livret_a_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/step_progress_bar.dart';

import '../widgets/logout_button.dart';
import '../widgets/theme_toggle_button.dart';

class EligibilityScreen extends ConsumerWidget {
  final VoidCallback? onNext;

  const EligibilityScreen({super.key, this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(livretAProvider);
    final notifier = ref.read(livretAProvider.notifier);
    final criteria = state.eligibility;
    final bool isApiIneligible =
        state.isLoadedFromApi && !state.isLivretAEligibleFromApi;

    if (kDebugMode) {
      print("ELIGIBILITY: isApiIneligible=$isApiIneligible");
    }

    return Scaffold(
      appBar: AppBar(
        leading: const LogoutButton(),
        title: const Text("Éligibilité Livret A"),
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(
              currentStep: 1,
              totalSteps: 5,
              title: "Vérification de vos conditions d'accès",
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isApiIneligible
                            ? AppTheme.error.withValues(alpha: 0.1)
                            : (criteria.isFullyEligible
                                  ? AppTheme.success.withValues(alpha: 0.1)
                                  : AppTheme.warning.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isApiIneligible
                              ? AppTheme.error.withValues(alpha: 0.4)
                              : (criteria.isFullyEligible
                                    ? AppTheme.success.withValues(alpha: 0.4)
                                    : AppTheme.warning.withValues(alpha: 0.4)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isApiIneligible
                                ? Icons.block_rounded
                                : (criteria.isFullyEligible
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_amber_rounded),
                            color: isApiIneligible
                                ? AppTheme.error
                                : (criteria.isFullyEligible
                                      ? AppTheme.success
                                      : AppTheme.warning),
                            size: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isApiIneligible
                                      ? "Client non éligible au Livret A (API)"
                                      : (criteria.isFullyEligible
                                            ? "Vous êtes éligible au Livret A !"
                                            : "Vérification des critères"),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isApiIneligible
                                        ? AppTheme.error
                                        : (criteria.isFullyEligible
                                              ? AppTheme.success
                                              : const Color(0xFFB45309)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isApiIneligible
                                      ? "Votre dossier bancaire ne comporte pas l'offre 'Livret A'."
                                      : (criteria.isFullyEligible
                                            ? "Vous pouvez procéder à l'ouverture de votre compte en toute sécurité."
                                            : "Selon la réglementation française, tous les critères ci-dessous sont évalués."),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Advantages Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.amber,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Avantages du Livret A",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildAdvantageItem(
                            "Taux garanti : 3.00% net d'impôt",
                          ),
                          _buildAdvantageItem(
                            "Épargne disponible à tout moment sans frais",
                          ),
                          _buildAdvantageItem(
                            "Plafond légal : 22 950 € par personne",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Criteria List (Sans Checkboxes)
                    Text(
                      "Critères réglementaires d'ouverture",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildCriterionTile(
                      context: context,
                      title: "Résidence fiscale en France",
                      subtitle: "Vous êtes domicilié fiscalement en France métropolitaine ou en Outre-Mer.",
                      isValid: criteria.isTaxResidentInFrance,
                    ),

                    _buildCriterionTile(
                      context: context,
                      title: "Absence d'autre Livret A",
                      subtitle: "Vous ne possédez aucun autre Livret A dans un autre établissement bancaire.",
                      isValid: criteria.hasNoOtherLivretA,
                    ),

                    _buildCriterionTile(
                      context: context,
                      title: "Capacité juridique",
                      subtitle:
                          "Vous êtes majeur ou représentant légal d'un mineur.",
                      isValid: criteria.isAdultOrLegalRep,
                    ),

                    _buildCriterionTile(
                      context: context,
                      title: "Consentement à la vérification",
                      subtitle: "J'autorise le contrôle de non-cumul du Livret A auprès de l'Administration Fiscale.",
                      isValid: criteria.acceptsDataCheck,
                    ),
                  ],
                ),
              ),
            ),

            // Footer Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: isApiIneligible
                  ? CustomButton(
                      text: "Voir le motif d'inéligibilité",
                      icon: Icons.warning_amber_rounded,
                      backgroundColor: AppTheme.error,
                      onPressed: () {
                        notifier.setStep(5);
                        if (onNext != null) onNext!();
                      },
                    )
                  : CustomButton(
                      text: "Continuer vers mes informations",
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        notifier.setStep(2);
                        if (onNext != null) onNext!();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    bool isValid = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isValid
                    ? AppTheme.success
                    : AppTheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isValid ? Icons.check_rounded : Icons.close_rounded,
                color: isValid ? Colors.white : AppTheme.error,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
