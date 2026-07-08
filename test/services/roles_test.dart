import 'package:flutter_test/flutter_test.dart';
import 'package:sar_app/services/roles.dart';

void main() {
  group('extractRoles', () {
    test('reads the roles list', () {
      expect(extractRoles({'roles': ['RECEPTION', 'ADMIN']}),
          ['RECEPTION', 'ADMIN']);
    });
    test('falls back to a single role', () {
      expect(extractRoles({'role': 'SALES_MOBILE'}), ['SALES_MOBILE']);
    });
    test('returns empty when neither field is present', () {
      expect(extractRoles({'name': 'x'}), isEmpty);
    });
    test('returns empty for null', () {
      expect(extractRoles(null), isEmpty);
    });
  });

  group('canAddCustomerFromRoles', () {
    test('true for RECEPTION', () {
      expect(canAddCustomerFromRoles(['RECEPTION']), isTrue);
    });
    test('true when SALES_MOBILE is among several roles', () {
      expect(canAddCustomerFromRoles(['ADMIN', 'SALES_MOBILE']), isTrue);
    });
    test('is case-insensitive', () {
      expect(canAddCustomerFromRoles(['sales_mobile']), isTrue);
    });
    test('false for unrelated roles', () {
      expect(canAddCustomerFromRoles(['ADMIN', 'HR']), isFalse);
    });
    test('false for an empty list', () {
      expect(canAddCustomerFromRoles([]), isFalse);
    });
  });
}
