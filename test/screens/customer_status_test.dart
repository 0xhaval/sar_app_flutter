import 'package:flutter_test/flutter_test.dart';
import 'package:sar_app/screens/customers.dart';

void main() {
  test('customer statuses match the backend seven-value vocabulary', () {
    expect(kCustomerStatuses, [
      'جديد',
      'تم التواصل',
      'زار المجمع',
      'مهتم',
      'غير مهتم',
      'مغلق - قام بالشراء',
      'مغلق - لم يشترِ',
    ]);
  });
}
