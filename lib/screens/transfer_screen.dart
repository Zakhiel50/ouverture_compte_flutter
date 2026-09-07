import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/livret_a_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/logout_button.dart';
import '../widgets/theme_toggle_button.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const TransferScreen({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _ibanController;
  late TextEditingController _recurringAmountController;

  final List<double> _presetAmounts = [10.0, 50.0, 150.0, 500.0, 1000.0];
  String _selectedAccount = 'Compte Courant Principal';
  bool _isRecurring = false;
  String _frequency = 'Mensuel';

  @override
  void initState() {
    super.initState();
    final transfer = ref.read(livretAProvider).transferInfo;
    _amountController = TextEditingController(
      text: transfer.initialAmount.toStringAsFixed(0),
    );
    _ibanController = TextEditingController(text: transfer.sourceIban);
    _recurringAmountController = TextEditingController(
      text: transfer.recurringAmount.toStringAsFixed(0),
    );
    _selectedAccount = transfer.sourceAccountName;
    _isRecurring = transfer.isRecurring;
    _frequency = transfer.recurringFrequency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _ibanController.dispose();
    _recurringAmountController.dispose();
    super.dispose();
  }

  void _saveAndProceed() {
    if (_formKey.currentState?.validate() ?? false) {
      final double amount = double.tryParse(_amountController.text) ?? 10.0;
      final double recurringAmount =
          double.tryParse(_recurringAmountController.text) ?? 0.0;

      final notifier = ref.read(livretAProvider.notifier);
      notifier.updateTransferInfo(
        initialAmount: amount,
        sourceAccountName: _selectedAccount,
        sourceIban: _ibanController.text.trim(),
        isRecurring: _isRecurring,
        recurringAmount: recurringAmount,
        recurringFrequency: _frequency,
      );
      notifier.setStep(4);
      if (widget.onNext != null) widget.onNext!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livretAProvider);
    final notifier = ref.read(livretAProvider.notifier);

    // Synchronisation si les données ont été chargées depuis l'API
    if (state.isLoadedFromApi &&
        _selectedAccount != state.transferInfo.sourceAccountName) {
      _selectedAccount = state.transferInfo.sourceAccountName;
      if (_ibanController.text.isEmpty ||
          _ibanController.text == 'FR76 1005 0000 1234 5678 9012 345') {
        _ibanController.text = state.transferInfo.sourceIban;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transfert d'Argent"),
        actions: const [LogoutButton(), ThemeToggleButton()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.setStep(2);
            if (widget.onBack != null) widget.onBack!();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(
              currentStep: 3,
              totalSteps: 5,
              title: "Alimentation initiale du compte",
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notice
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Réglementation : Le premier versement sur votre ${state.selectedProduct} doit être d'un montant minimum de 10 €.",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "Montant du virement initial (€)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Preset Pills
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _presetAmounts.map((amt) {
                          final currentInput = double.tryParse(
                            _amountController.text,
                          );
                          final isSelected = currentInput == amt;
                          return ChoiceChip(
                            label: Text('${amt.toInt()} €'),
                            selected: isSelected,
                            selectedColor: AppTheme.accent,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _amountController.text = amt.toStringAsFixed(
                                    0,
                                  );
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: "Montant personnalisé (€)",
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefixIcon: Icons.euro_symbol_rounded,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Veuillez indiquer un montant";
                          }
                          final parsed = double.tryParse(val);
                          if (parsed == null || parsed < 10.0) {
                            return "Le versement minimum est de 10 €";
                          }
                          if (parsed > 22950.0) {
                            return "Le plafond légal autorise pour ${state.selectedProduct} est de 22 950 €";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "Compte d'origine",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        key: ValueKey(_selectedAccount),
                        initialValue: _selectedAccount,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        items:
                            <String>{
                              _selectedAccount,
                              'Compte Courant Principal',
                              'Autre Banque Externe',
                            }.map((account) {
                              return DropdownMenuItem<String>(
                                value: account,
                                child: Text(
                                  account == 'Autre Banque Externe'
                                      ? 'Autre Banque (Virement externe IBAN)'
                                      : account,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedAccount = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: "IBAN de prélèvement",
                        controller: _ibanController,
                        prefixIcon: Icons.credit_card_outlined,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Veuillez renseigner votre IBAN";
                          }
                          if (val.length < 15) {
                            return "IBAN invalide";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Optional Recurring Transfer
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Programmer des versements automatiques",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: const Text(
                                  "Alimentez votre épargne chaque mois à votre rythme",
                                  style: TextStyle(fontSize: 13),
                                ),
                                value: _isRecurring,
                                activeThumbColor: AppTheme.accent,
                                onChanged: (val) {
                                  setState(() {
                                    _isRecurring = val;
                                  });
                                },
                              ),
                              if (_isRecurring) ...[
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        label: "Montant périodique (€)",
                                        controller: _recurringAmountController,
                                        keyboardType: TextInputType.number,
                                        prefixIcon: Icons.repeat_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Fréquence",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            initialValue: _frequency,
                                            decoration: const InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 16,
                                                  ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Mensuel',
                                                child: Text('Mensuel'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Trimestriel',
                                                child: Text('Trimestriel'),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _frequency = val;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomButton(
                text: "Voir le récapitulatif de ma demande",
                icon: Icons.arrow_forward_rounded,
                onPressed: _saveAndProceed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
