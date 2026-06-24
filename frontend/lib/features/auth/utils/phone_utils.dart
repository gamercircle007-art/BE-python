/// Normalize phone to E.164 for Paythan API.
String normalizePhone(String phone) {
  final cleaned = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
  if (cleaned.startsWith('+')) return cleaned;
  if (cleaned.length == 10) return '+91$cleaned';
  return '+$cleaned';
}

String maskPhone(String phone) {
  if (phone.length < 4) return phone;
  return '${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}';
}