/// Form field validators. Return `null` when valid, or an error string.
class Validators {
  Validators._();

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!re.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return '$field is required';
    return null;
  }

  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone is required';
    if (!RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(v)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Positive monetary / weight amount.
  static String? positiveNumber(String? value, {String field = 'Amount'}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '$field is required';
    final n = double.tryParse(v);
    if (n == null) return '$field must be a number';
    if (n <= 0) return '$field must be greater than zero';
    return null;
  }
}
