import 'package:vitalog/features/family_health/data/privacy/redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lab names lose addresses and contact details', () {
    expect(
        Redactor.labName('Sunrise Pathology Lab, 12 MG Road, Ph: 98450 12345'),
        'Sunrise Pathology Lab');
    expect(Redactor.labName('Apollo Diagnostics  Tel 080-2345-6789'),
        'Apollo Diagnostics');
    expect(
        Redactor.labName('Metro Labs | www.metrolabs.in | info@metrolabs.in'),
        'Metro Labs');
    expect(Redactor.labName('Dr. Lal PathLabs'), 'Dr. Lal PathLabs');
    expect(Redactor.labName("St. John's Hospital Laboratory"),
        "St. John's Hospital Laboratory");
  });

  test('free text keeps the words, drops phones, emails and links', () {
    expect(Redactor.text('Cystatin C call +91 98450 12345'), 'Cystatin C call');
    expect(Redactor.text('Note: mail reports@lab.com'), 'Note: mail');
    expect(Redactor.text('Vitamin B12'), 'Vitamin B12');
  });
}
