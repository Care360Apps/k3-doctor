/// A missing or malformed birth date must remain unset, never become a
/// fabricated date or prevent the rest of a professional profile loading.
class Care360ProfileDate {
  static DateTime? parse(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
    final date = DateTime.tryParse(text);
    if (date == null) return null;
    final canonical = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return canonical == text ? date : null;
  }
}
