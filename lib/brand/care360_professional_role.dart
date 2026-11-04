/// Client-only role presentation. The Laravel backend enforces permissions.
class Care360ProfessionalRole {
  static bool isProvider(String? role) => role == 'provider';
  static bool canOfferHomeVisit(String? role) => isProvider(role);
  static bool canCreatePrescription(String? role) => role == 'doctor';
}
