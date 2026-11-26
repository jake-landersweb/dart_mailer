import 'package:test/test.dart';

import '../bin/data/recipients.dart';

void main() {
  test('trims both individual and legacy comma-separated addresses', () {
    expect(
      normalizeRecipients(
          'recipient',
          [
            ' first+tag@example.test ',
            ' Second@example.test, third@example.test ',
          ],
          required: true),
      ['first+tag@example.test', 'Second@example.test', 'third@example.test'],
    );
  });

  test('accepts absent optional addresses and rejects absent To', () {
    expect(normalizeRecipients('cc', []), isEmpty);
    expect(() => normalizeRecipients('recipient', [], required: true),
        throwsFormatException);
  });

  test('rejects malformed or empty entries without dropping any address', () {
    for (final invalid in [
      'missing-at',
      'two@@example.test',
      'missing-domain@',
      '@example.test',
      'two words@example.test',
      'Name <address@example.test>',
      'valid@example.test,',
      'valid@example.test\r\nBcc: extra@example.test',
    ]) {
      expect(() => normalizeRecipients('bcc', [invalid]), throwsFormatException,
          reason: invalid);
    }
  });
}
