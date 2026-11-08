/// Local validation before creating or uploading a clinical prescription.
/// This improves input safety; the Laravel backend remains authoritative.
class Care360PrescriptionValidation {
  static const maxMedicines = 50;

  /// Null means the prescription is structurally valid.
  static String? validate(List<Map<String, dynamic>> medicines) {
    if (medicines.isEmpty || medicines.length > maxMedicines) {
      return 'Add between 1 and $maxMedicines medicines.';
    }
    for (final medicine in medicines) {
      final name = medicine['medicine'];
      if (name is! String || name.trim().isEmpty || name.trim().length > 160) {
        return 'Select a valid medicine.';
      }

      final rawDays = medicine['days'];
      final days = rawDays is int ? rawDays : int.tryParse(rawDays?.toString() ?? '');
      if (days == null || days < 1 || days > 365) {
        return 'Duration must be between 1 and 365 days.';
      }

      bool scheduled(dynamic value) => value == true || value == 1 || value == '1';
      final fields = ['morning', 'afternoon', 'night'];
      if (fields.any((field) {
        final value = medicine[field];
        return value != true && value != false && value != 0 &&
            value != 1 && value != '0' && value != '1';
      }) || !fields.any((field) => scheduled(medicine[field]))) {
        return 'Select at least one valid daily dose time.';
      }
    }
    return null;
  }
}
