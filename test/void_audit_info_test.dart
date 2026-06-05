import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/api/void_audit_info.dart';

void main() {
  test('VoidAuditInfo parses snake_case transaction fields', () {
    final audit = VoidAuditInfo.tryFromJson({
      'status': 'void',
      'void_reason': 'Duplicate entry',
      'voided_by': {
        'id': 'u1',
        'username': 'cashier1',
        'name': 'Ana Lopez',
      },
      'voided_at': '2026-05-16T10:00:00.000Z',
    });

    expect(audit, isNotNull);
    expect(audit!.reason, 'Duplicate entry');
    expect(audit.voidedBy?.name, 'Ana Lopez');
    expect(VoidAuditInfo.isVoidStatus('void'), isTrue);
  });

  test('VoidAuditInfo parses camelCase ticket void response', () {
    final audit = VoidAuditInfo.tryFromJson({
      'status': 'VOID',
      'voidReason': 'Wrong plate',
      'voidedBy': {
        'id': 'u2',
        'username': 'jdoe',
        'firstName': 'John',
        'lastName': 'Doe',
      },
      'voidedAt': '2026-05-16T11:00:00.000Z',
    });

    expect(audit, isNotNull);
    expect(audit!.reason, 'Wrong plate');
    expect(audit.voidedBy?.name, 'John Doe');
    expect(VoidAuditInfo.isVoidStatus('VOID'), isTrue);
  });
}
