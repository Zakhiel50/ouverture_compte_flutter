import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/livret_a_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/logout_button.dart';
import '../widgets/theme_toggle_button.dart';

class SuccessScreen extends ConsumerWidget {
  final VoidCallback? onReset;

  const SuccessScreen({super.key, this.onReset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(livretAProvider);
    final notifier = ref.read(livretAProvider.notifier);
    final user = state.userInfo;
    final transfer = state.transferInfo;
    final String iban = state.generatedIban;
    final bool isEligible = state.isLivretAEligibleFromApi;

    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    );

    final String soldeFormatted = currencyFormat.format(transfer.initialAmount);

    // -----------------------------------------------------------------------
    // CAS INÉLIGIBLE : Si le tableau offresEligibles ne contient pas "Livret A"
    // -----------------------------------------------------------------------
    if (!isEligible) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          actions: const [LogoutButton(), ThemeToggleButton()],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Icone d'alerte rouge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: AppTheme.error,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),

                // Titre principal
                Text(
                  "Demande Non Éligible",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  "Désolé ${user.firstName}, vous ne remplissez pas les conditions requises pour cette offre.",
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Carte d'alerte explicite requise
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.error,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "ALERTE D'INÉLIGIBILITÉ",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Le client n'est pas éligible à l'ouverture d'un Livret A.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "L'offre 'Livret A' n'apparaît pas dans la liste des offres bancaires autorisées pour votre profil (tableau offresEligibles).",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (state.offresEligiblesApi.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text(
                          "Vos autres offres disponibles :",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: state.offresEligiblesApi.map((offre) {
                            return Chip(
                              label: Text(
                                offre,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // CTA pour rediriger à la 1ère page: Éligibilité
                CustomButton(
                  text: "Retour à l'Éligibilité",
                  icon: Icons.assignment_return_rounded,
                  backgroundColor: AppTheme.primary,
                  onPressed: () {
                    notifier.setStep(1);
                    if (onReset != null) onReset!();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // -----------------------------------------------------------------------
    // CAS ÉLIGIBLE : Écran de Succès classique avec solde de la page 3
    // -----------------------------------------------------------------------
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: const [LogoutButton(), ThemeToggleButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Animated Check Icon Badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                "Livret A Ouvert !",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                "Félicitations ${user.firstName}, votre compte d'épargne est officiellement actif.",
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // PROMINENT BALANCE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "SOLDE INITIAL DU COMPTE",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      soldeFormatted,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Solde initial : ($soldeFormatted)",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Digital Banking Card Component
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "LIVRET A",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "ACTIF • 3,00%",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      iban,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TITULAIRE",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.fullName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "SOLDE DU COMPTE",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              soldeFormatted,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Télécharger RIB",
                      icon: Icons.download_rounded,
                      isOutlined: true,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("RIB du Livret A téléchargé en PDF"),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: "Nouveau Virement",
                      icon: Icons.send_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Module de virement externe ouvert"),
                            backgroundColor: AppTheme.accent,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              CustomButton(
                text: "Recommencer le parcours",
                icon: Icons.refresh_rounded,
                isOutlined: true,
                onPressed: () {
                  notifier.reset();
                  if (onReset != null) onReset!();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
