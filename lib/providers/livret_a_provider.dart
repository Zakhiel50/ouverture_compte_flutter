import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/livret_a_model.dart';
import '../services/api_service.dart';
import '../services/manage-db.dart';

class LivretAState {
  final int currentStep;
  final String selectedProduct;
  final EligibilityCriteria eligibility;
  final UserInfo userInfo;
  final TransferInfo transferInfo;
  final String generatedIban;
  final bool isAccountOpened;
  final bool isLoadedFromApi;
  final bool isLivretAEligibleFromApi;
  final List<String> offresEligiblesApi;

  LivretAState({
    this.currentStep = 0,
    this.selectedProduct = 'Livret A',
    EligibilityCriteria? eligibility,
    UserInfo? userInfo,
    TransferInfo? transferInfo,
    this.generatedIban = 'FR76 3000 4000 1212 3456 7890 188',
    this.isAccountOpened = false,
    this.isLoadedFromApi = false,
    this.isLivretAEligibleFromApi = true,
    this.offresEligiblesApi = const [],
  })  : eligibility = eligibility ?? EligibilityCriteria(),
        userInfo = userInfo ?? UserInfo(),
        transferInfo = transferInfo ?? TransferInfo();

  LivretAState copyWith({
    int? currentStep,
    String? selectedProduct,
    EligibilityCriteria? eligibility,
    UserInfo? userInfo,
    TransferInfo? transferInfo,
    String? generatedIban,
    bool? isAccountOpened,
    bool? isLoadedFromApi,
    bool? isLivretAEligibleFromApi,
    List<String>? offresEligiblesApi,
  }) {
    return LivretAState(
      currentStep: currentStep ?? this.currentStep,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      eligibility: eligibility ?? this.eligibility,
      userInfo: userInfo ?? this.userInfo,
      transferInfo: transferInfo ?? this.transferInfo,
      generatedIban: generatedIban ?? this.generatedIban,
      isAccountOpened: isAccountOpened ?? this.isAccountOpened,
      isLoadedFromApi: isLoadedFromApi ?? this.isLoadedFromApi,
      isLivretAEligibleFromApi: isLivretAEligibleFromApi ?? this.isLivretAEligibleFromApi,
      offresEligiblesApi: offresEligiblesApi ?? this.offresEligiblesApi,
    );
  }
}

class LivretANotifier extends StateNotifier<LivretAState> {
  LivretANotifier() : super(LivretAState());

  void setStep(int step) {
    if (step >= 0 && step <= 5) {
      if (state.isLoadedFromApi &&
          !state.isLivretAEligibleFromApi &&
          (step == 2 || step == 3 || step == 4)) {
        state = state.copyWith(currentStep: 5);
        return;
      }
      state = state.copyWith(currentStep: step);
    }
  }

  bool evaluateProductEligibility(String selectedProduct, List<String> offresEligibles, bool isGlobalEligible) {
    if (!isGlobalEligible) return false;
    if (offresEligibles.isEmpty) return false;

    final targetLower = selectedProduct.toLowerCase().trim();

    return offresEligibles.any((offre) {
      final offreLower = offre.toLowerCase().trim();

      if (offreLower == targetLower) return true;
      if (targetLower == 'livret a' && offreLower.contains('livret a')) return true;
      if (targetLower.contains('populaire') && (offreLower.contains('lep') || offreLower.contains('populaire'))) return true;
      if (targetLower == 'pel' && offreLower.contains('pel')) return true;
      if (targetLower.contains('jeune') && offreLower.contains('jeune')) return true;
      if (targetLower.contains('etudiant') && (offreLower.contains('etudiant') || offreLower.contains('étudiant'))) return true;
      if (targetLower.contains('pro') && offreLower.contains('pro')) return true;
      if (targetLower.contains('mastercard') && (offreLower.contains('mastercard') || offreLower.contains('visa'))) return true;
      if (targetLower.contains('prêt') || targetLower.contains('pret')) {
        return offreLower.contains('prêt') || offreLower.contains('pret') || offreLower.contains('credit');
      }

      return false;
    });
  }

  Future<bool> checkEligibilityForProduct(String selectedProduct) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final dbRecord = await ManageDbService().getUserRecord(user.uid);
        if (dbRecord != null && dbRecord['produitsOuverts'] != null) {
          final rawList = dbRecord['produitsOuverts'] as List<dynamic>;
          final openedNames = rawList.map((item) {
            if (item is Map) {
              return item['nomProduit']?.toString() ?? '';
            }
            return item.toString();
          }).toList();

          final targetLower = selectedProduct.toLowerCase().trim();

          final bool isAlreadyOpened = openedNames.any((name) {
            final nameLower = name.toLowerCase().trim();
            if (nameLower == targetLower) return true;
            if (targetLower == 'livret a' && nameLower.contains('livret a')) return true;
            if (targetLower.contains('populaire') && (nameLower.contains('lep') || nameLower.contains('populaire'))) return true;
            if (targetLower == 'pel' && nameLower.contains('pel')) return true;
            if (targetLower.contains('jeune') && nameLower.contains('jeune')) return true;
            if (targetLower.contains('etudiant') && (nameLower.contains('etudiant') || nameLower.contains('étudiant'))) return true;
            if (targetLower.contains('pro') && nameLower.contains('pro')) return true;
            if (targetLower.contains('mastercard') && (nameLower.contains('mastercard') || nameLower.contains('visa'))) return true;
            return false;
          });

          // Si le produit est déjà ouvert en BDD, l'utilisateur n'est PAS éligible !
          if (isAlreadyOpened) {
            if (kDebugMode) {
              print("FIRESTORE: Le produit '$selectedProduct' est DÉJÀ OUVERT en BDD. Éligibilité = false");
            }
            return false;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("FIRESTORE CHECK ERROR: $e");
        }
      }
    }

    // Seule la BDD fait foi : produit non présent en BDD => ÉLIGIBLE
    return true;
  }

  void selectProduct(String product) async {
    final bool isEligible = await checkEligibilityForProduct(product);

    final updatedCriteria = EligibilityCriteria(
      isTaxResidentInFrance: true,
      hasNoOtherLivretA: isEligible,
      isAdultOrLegalRep: true,
      acceptsDataCheck: true,
    );

    state = state.copyWith(
      selectedProduct: product,
      currentStep: 1,
      isLivretAEligibleFromApi: isEligible,
      eligibility: updatedCriteria,
    );
  }

  void loadFromApiData(Map<String, dynamic> apiData) async {
    final newUserInfo = UserInfo(
      firstName: state.userInfo.firstName,
      lastName: state.userInfo.lastName,
      email: state.userInfo.email,
      phone: state.userInfo.phone,
      birthDate: state.userInfo.birthDate,
      address: state.userInfo.address,
      taxId: state.userInfo.taxId,
    );

    final newTransfer = TransferInfo(
      initialAmount: state.transferInfo.initialAmount,
      sourceAccountName: state.transferInfo.sourceAccountName,
      sourceIban: state.transferInfo.sourceIban,
      isRecurring: state.transferInfo.isRecurring,
      recurringAmount: state.transferInfo.recurringAmount,
      recurringFrequency: state.transferInfo.recurringFrequency,
    );

    if (apiData.containsKey('user') && apiData['user'] != null) {
      final userJson = Map<String, dynamic>.from(apiData['user'] as Map);
      newUserInfo.firstName = userJson['prenom'] ?? newUserInfo.firstName;
      newUserInfo.lastName = userJson['nom'] ?? newUserInfo.lastName;
      newUserInfo.email = userJson['email'] ?? newUserInfo.email;
      newUserInfo.phone = userJson['telephone'] ?? newUserInfo.phone;

      if (userJson['dateNaissance'] != null) {
        final parts = (userJson['dateNaissance'] as String).split('-');
        if (parts.length == 3) {
          newUserInfo.birthDate = '${parts[2]}/${parts[1]}/${parts[0]}';
        } else {
          newUserInfo.birthDate = userJson['dateNaissance'];
        }
      }
    }

    if (apiData.containsKey('comptes') && (apiData['comptes'] as List).isNotEmpty) {
      final compte = Map<String, dynamic>.from((apiData['comptes'] as List).first as Map);
      newTransfer.sourceAccountName = compte['libelle'] ?? 'Compte Courant';
      newTransfer.sourceIban = compte['numeroCompte'] ?? newTransfer.sourceIban;
    }

    final bool isProductEligible = await checkEligibilityForProduct(state.selectedProduct);

    final newEligibility = EligibilityCriteria(
      isTaxResidentInFrance: true,
      hasNoOtherLivretA: isProductEligible,
      isAdultOrLegalRep: true,
      acceptsDataCheck: true,
    );

    state = state.copyWith(
      userInfo: newUserInfo,
      eligibility: newEligibility,
      transferInfo: newTransfer,
      isLivretAEligibleFromApi: isProductEligible,
      isLoadedFromApi: true,
    );
  }

  void updateEligibility({
    bool? isTaxResident,
    bool? hasNoOtherLivretA,
    bool? isAdultOrLegalRep,
    bool? acceptsDataCheck,
  }) {
    final newEligibility = EligibilityCriteria(
      isTaxResidentInFrance: isTaxResident ?? state.eligibility.isTaxResidentInFrance,
      hasNoOtherLivretA: hasNoOtherLivretA ?? state.eligibility.hasNoOtherLivretA,
      isAdultOrLegalRep: isAdultOrLegalRep ?? state.eligibility.isAdultOrLegalRep,
      acceptsDataCheck: acceptsDataCheck ?? state.eligibility.acceptsDataCheck,
    );
    state = state.copyWith(eligibility: newEligibility);
  }

  void updateUserInfo({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? birthDate,
    String? address,
    String? taxId,
  }) {
    final newUserInfo = UserInfo(
      firstName: firstName ?? state.userInfo.firstName,
      lastName: lastName ?? state.userInfo.lastName,
      email: email ?? state.userInfo.email,
      phone: phone ?? state.userInfo.phone,
      birthDate: birthDate ?? state.userInfo.birthDate,
      address: address ?? state.userInfo.address,
      taxId: taxId ?? state.userInfo.taxId,
    );
    state = state.copyWith(userInfo: newUserInfo);
  }

  void updateTransferInfo({
    double? initialAmount,
    String? sourceAccountName,
    String? sourceIban,
    bool? isRecurring,
    double? recurringAmount,
    String? recurringFrequency,
  }) {
    final newTransfer = TransferInfo(
      initialAmount: initialAmount ?? state.transferInfo.initialAmount,
      sourceAccountName: sourceAccountName ?? state.transferInfo.sourceAccountName,
      sourceIban: sourceIban ?? state.transferInfo.sourceIban,
      isRecurring: isRecurring ?? state.transferInfo.isRecurring,
      recurringAmount: recurringAmount ?? state.transferInfo.recurringAmount,
      recurringFrequency: recurringFrequency ?? state.transferInfo.recurringFrequency,
    );
    state = state.copyWith(transferInfo: newTransfer);
  }
  Future<void> confirmAccountOpening() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await ManageDbService().saveUserRecord(
          userId: currentUser.uid,
          titulairePrenom: state.userInfo.firstName,
          titulaireNom: state.userInfo.lastName,
          nomProduit: state.selectedProduct,
          soldeInitial: state.transferInfo.initialAmount,
        );
        if (kDebugMode) {
          print("FIRESTORE: Enregistré avec succès pour ${currentUser.uid}");
        }
      } catch (e) {
        if (kDebugMode) {
          print("FIRESTORE ERROR: $e");
        }
      }
    }
    state = state.copyWith(isAccountOpened: true, currentStep: 5);
  }

  void reset() {
    state = LivretAState();
  }
}

/// Provider principal Riverpod partagé dans toute l'application
final livretAProvider = StateNotifierProvider<LivretANotifier, LivretAState>((ref) {
  return LivretANotifier();
});

/// FutureProvider Riverpod pour consommer les données API de l'utilisateur
final userDataApiProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  return ApiService.fetchUserData(userId: userId);
});
