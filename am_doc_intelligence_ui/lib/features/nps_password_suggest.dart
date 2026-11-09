/// CRA NPS statement PDF unlock: first 4 letters of first name (lowercase,
/// pad with leading `9`s if shorter) + DOB as DDMM.
///
/// Example: Om + 01/11/1975 → `99om0111`.
String buildNpsStatementPassword(String firstName, DateTime dob) {
  final letters = firstName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z]'), '');
  var namePart = letters.length >= 4 ? letters.substring(0, 4) : letters;
  while (namePart.length < 4) {
    namePart = '9$namePart';
  }
  final dd = dob.day.toString().padLeft(2, '0');
  final mm = dob.month.toString().padLeft(2, '0');
  return '$namePart$dd$mm';
}

/// Parse DOB from `DD/MM/YYYY`, `DD-MM-YYYY`, or `DDMMYYYY`.
DateTime? parseNpsDobInput(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 8) {
    final dd = int.tryParse(digits.substring(0, 2));
    final mm = int.tryParse(digits.substring(2, 4));
    final yyyy = int.tryParse(digits.substring(4, 8));
    if (dd == null || mm == null || yyyy == null) return null;
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    try {
      return DateTime(yyyy, mm, dd);
    } catch (_) {
      return null;
    }
  }
  final parts = s.split(RegExp(r'[/\-.]'));
  if (parts.length == 3) {
    final dd = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    final yyyy = int.tryParse(parts[2]);
    if (dd == null || mm == null || yyyy == null) return null;
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    try {
      return DateTime(yyyy, mm, dd);
    } catch (_) {
      return null;
    }
  }
  return null;
}
