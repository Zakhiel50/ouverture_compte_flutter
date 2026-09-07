import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/livret_a_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/logout_button.dart';
import '../widgets/theme_toggle_button.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onBack;

  const SummaryScreen({super.key, this.onConfirm, this.onBack});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _acceptTerms = false;
  bool _isSubmitting = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
  );

  void _handleConfirmOpening() async {
    if (!_acceptTerms) return;

    setState(() {
      _isSubmitting = true;
    });

    // Simulation d'une validation réseau
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final notifier = ref.read(livretAProvider.notifier);
    await notifier.confirmAccountOpening();

    if (widget.onConfirm != null) {
      widget.onConfirm!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livretAProvider);
    final notifier = ref.read(livretAProvider.notifier);
    final user = state.userInfo;
    final transfer = state.transferInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Récapitulatif du Transfert"),
        actions: const [LogoutButton(), ThemeToggleButton()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.setStep(3);
            if (widget.onBack != null) widget.onBack!();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(
              currentStep: 4,
              totalSteps: 5,
              title: "Synthèse et confirmation de l'opération",
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Highlight Card - Page 3 Recap
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
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
                                "Récapitulatif du Virement Initial",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Étape 3/5",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currencyFormat.format(transfer.initialAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Montant qui sera crédité sur votre nouveau ${state.selectedProduct}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Detailed breakdown of Page 3 info
                    const Text(
                      "Détails du paiement",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: Icons.account_balance,
                              label: "Compte émetteur",
                              value: transfer.sourceAccountName,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              icon: Icons.credit_card,
                              label: "IBAN prélevé",
                              value: transfer.sourceIban,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              icon: Icons.event,
                              label: "Date d'exécution",
                              value: "Immédiate dès l'ouverture",
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              icon: Icons.money_off_csred_outlined,
                              label: "Frais de dossier & virement",
                              value: "0,00 € (Gratuit)",
                              valueColor: AppTheme.success,
                            ),
                            if (transfer.isRecurring) ...[
                              const Divider(height: 24),
                              _buildDetailRow(
                                icon: Icons.repeat_rounded,
                                label: "Virement programmé",
                                value:
                                    "${_currencyFormat.format(transfer.recurringAmount)} / ${transfer.recurringFrequency}",
                                valueColor: AppTheme.accent,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Holder Info Card
                    const Text(
                      "Titulaire du compte",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: Icons.person_outline,
                              label: "Nom complet",
                              value: user.fullName,
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              icon: Icons.email_outlined,
                              label: "E-mail de confirmation",
                              value: user.email,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Terms Checkbox
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _acceptTerms
                              ? AppTheme.accent
                              : AppTheme.border,
                          width: _acceptTerms ? 2 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        activeColor: AppTheme.accent,
                        value: _acceptTerms,
                        onChanged: (val) {
                          setState(() {
                            _acceptTerms = val ?? false;
                          });
                        },
                        title: const Text(
                          "Confirmation sur l'honneur",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "Je confirme le virement initial de ${_currencyFormat.format(transfer.initialAmount)} et j'autorise la création officielle de mon ${state.selectedProduct}.",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Submit Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomButton(
                text: "Ouvrir mon ${state.selectedProduct}",
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSubmitting,
                onPressed: _acceptTerms ? _handleConfirmOpening : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
