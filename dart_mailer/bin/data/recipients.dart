/// Normalizes the comma-separated mailbox lists used by the queue.
List<String> normalizeRecipients(
  String field,
  List<String> entries, {
  bool required = false,
}) {
  final addresses =
      entries.expand((entry) => entry.split(',')).map((entry) => entry.trim());
  final normalized = addresses.toList();
  if (required && normalized.isEmpty) {
    throw FormatException('$field must contain at least one email address');
  }
  for (var i = 0; i < normalized.length; i++) {
    final parts = normalized[i].split('@');
    if (parts.length != 2 ||
        parts.any((part) => !_mailboxPart.hasMatch(part))) {
      throw FormatException('$field entry ${i + 1} is not an email address');
    }
  }
  return normalized;
}

final _mailboxPart = RegExp(r'^[^\x00-\x20\x7f-\uffff<>,;]+$');
