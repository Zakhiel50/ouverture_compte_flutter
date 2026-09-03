import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/livret_a_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/step_progress_bar.dart';

import '../widgets/logout_button.dart';
import '../widgets/theme_toggle_button.dart';

class UserInfoScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const UserInfoScreen({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends ConsumerState<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  late TextEditingController _taxIdController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(livretAProvider).userInfo;
    _firstNameController = TextEditingController(text: user.firstName);
    _lastNameController = TextEditingController(text: user.lastName);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone);
    _birthDateController = TextEditingController(text: user.birthDate);
    _addressController = TextEditingController(text: user.address);
    _taxIdController = TextEditingController(text: user.taxId);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _saveAndSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final notifier = ref.read(livretAProvider.notifier);
      notifier.updateUserInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        address: _addressController.text.trim(),
        taxId: _taxIdController.text.trim(),
      );
      notifier.setStep(3);
      if (widget.onNext != null) widget.onNext!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(livretAProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Informations Utilisateur"),
        actions: const [LogoutButton(), ThemeToggleButton()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.setStep(1);
            if (widget.onBack != null) widget.onBack!();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(
              currentStep: 2,
              totalSteps: 5,
              title: "Vos informations personnelles",
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: "Prénom",
                              controller: _firstNameController,
                              prefixIcon: Icons.person_outline,
                              validator: (val) => val == null || val.isEmpty
                                  ? "Veuillez entrer votre prénom"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: "Nom",
                              controller: _lastNameController,
                              prefixIcon: Icons.person_outline,
                              validator: (val) => val == null || val.isEmpty
                                  ? "Veuillez entrer votre nom"
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: "Adresse e-mail",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Veuillez entrer votre e-mail";
                          }
                          if (!val.contains("@") || !val.contains(".")) {
                            return "Adresse e-mail invalide";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: "Date de naissance",
                              hint: "JJ/MM/AAAA",
                              controller: _birthDateController,
                              keyboardType: TextInputType.datetime,
                              prefixIcon: Icons.calendar_today_outlined,
                              validator: (val) => val == null || val.isEmpty
                                  ? "Date requise"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: "Téléphone",
                              hint: "06 12 34 56 78",
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (val) => val == null || val.isEmpty
                                  ? "Numéro requis"
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: "Adresse de résidence",
                        controller: _addressController,
                        prefixIcon: Icons.home_outlined,
                        maxLines: 2,
                        validator: (val) => val == null || val.isEmpty
                            ? "Adresse requise"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: "Numéro d'Identification Fiscale (NIF)",
                        hint: "13 chiffres figurant sur votre avis d'impôt",
                        controller: _taxIdController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.receipt_long_outlined,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Le numéro NIF est obligatoire pour le Livret A";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomButton(
                text: "Étape suivante : Transfert d'argent",
                icon: Icons.arrow_forward_rounded,
                onPressed: _saveAndSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
