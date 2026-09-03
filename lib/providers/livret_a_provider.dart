import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/livret_a_model.dart';
import '../services/api_service.dart';

class LivretAState {
  final int currentStep;
  final EligibilityCriteria eligibility;
  final UserInfo userInfo;
  final TransferInfo transferInfo;
  final String generatedIban;
  final bool isAccountOpened;
  final bool isLoadedFromApi;
  final bool isLivretAEligibleFromApi;
  final List<String> offresEligiblesApi;

  LivretAState({
    this.currentStep = 1,
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
    if (step >= 1 && step <= 5) {
      if (state.isLoadedFromApi &&
          !state.isLivretAEligibleFromApi &&
          (step == 2 || step == 3 || step == 4)) {
        state = state.copyWith(currentStep: 5);
        return;
      }
      state = state.copyWith(currentStep: step);
    }
  }

  void loadFromApiData(Map<String, dynamic> apiData) {
    final newUserInfo = UserInfo(
      firstName: state.userInfo.firstName,
      lastName: state.userInfo.lastName,
      email: state.userInfo.email,
      phone: state.userInfo.phone,
      birthDate: state.userInfo.birthDate,
      address: state.userInfo.address,
      taxId: state.userInfo.taxId,
    );

    final newEligibility = EligibilityCriteria(
      isTaxResidentInFrance: state.eligibility.isTaxResidentInFrance,
      hasNoOtherLivretA: state.eligibility.hasNoOtherLivretA,
      isAdultOrLegalRep: state.eligibility.isAdultOrLegalRep,
      acceptsDataCheck: state.eligibility.acceptsDataCheck,
    );

    final newTransfer = TransferInfo(
      initialAmount: state.transferInfo.initialAmount,
      sourceAccountName: state.transferInfo.sourceAccountName,
      sourceIban: state.transferInfo.sourceIban,
      isRecurring: state.transferInfo.isRecurring,
      recurringAmount: state.transferInfo.recurringAmount,
      recurringFrequency: state.transferInfo.recurringFrequency,
    );

    List<String> offres = [];
    bool isLivretAEligible = true;

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

      if (userJson['eligibilite'] != null) {
        final elig = Map<String, dynamic>.from(userJson['eligibilite'] as Map);
        offres = (elig['offresEligibles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        final bool hasLivretA = offres.contains('Livret A');
        isLivretAEligible = elig['estEligible'] == true && hasLivretA;

        newEligibility.isTaxResidentInFrance = isLivretAEligible;
        newEligibility.hasNoOtherLivretA = isLivretAEligible;
        newEligibility.isAdultOrLegalRep = true;
        newEligibility.acceptsDataCheck = true;
      }
    }

    if (apiData.containsKey('comptes') && (apiData['comptes'] as List).isNotEmpty) {
      final compte = Map<String, dynamic>.from((apiData['comptes'] as List).first as Map);
      newTransfer.sourceAccountName = compte['libelle'] ?? 'Compte Courant';
      newTransfer.sourceIban = compte['numeroCompte'] ?? newTransfer.sourceIban;
    }

    state = state.copyWith(
      userInfo: newUserInfo,
      eligibility: newEligibility,
      transferInfo: newTransfer,
      offresEligiblesApi: offres,
      isLivretAEligibleFromApi: isLivretAEligible,
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

  void confirmAccountOpening() {
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
