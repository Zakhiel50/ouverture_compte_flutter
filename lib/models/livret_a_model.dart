class EligibilityCriteria {
  bool isTaxResidentInFrance;
  bool hasNoOtherLivretA;
  bool isAdultOrLegalRep;
  bool acceptsDataCheck;

  EligibilityCriteria({
    this.isTaxResidentInFrance = true,
    this.hasNoOtherLivretA = true,
    this.isAdultOrLegalRep = true,
    this.acceptsDataCheck = true,
  });

  bool get isFullyEligible =>
      isTaxResidentInFrance &&
      hasNoOtherLivretA &&
      isAdultOrLegalRep &&
      acceptsDataCheck;
}

class UserInfo {
  String firstName;
  String lastName;
  String email;
  String phone;
  String birthDate;
  String address;
  String taxId;

  UserInfo({
    this.firstName = 'Jean',
    this.lastName = 'Dupont',
    this.email = 'jean.dupont@email.fr',
    this.phone = '06 12 34 56 78',
    this.birthDate = '15/05/1990',
    this.address = '12 Rue de la Paix, 75002 Paris',
    this.taxId = '1234567890123',
  });

  String get fullName => '$firstName $lastName'.trim();
}

class TransferInfo {
  double initialAmount;
  String sourceAccountName;
  String sourceIban;
  bool isRecurring;
  double recurringAmount;
  String recurringFrequency;

  TransferInfo({
    this.initialAmount = 150.0,
    this.sourceAccountName = 'Compte Courant Principal',
    this.sourceIban = 'FR76 1005 0000 1234 5678 9012 345',
    this.isRecurring = false,
    this.recurringAmount = 50.0,
    this.recurringFrequency = 'Mensuel',
  });
}
