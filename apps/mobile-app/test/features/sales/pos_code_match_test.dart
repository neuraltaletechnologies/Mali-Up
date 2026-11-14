import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/sales/presentation/widgets/pos_catalog.dart';

void main() {
  final soap = <String, dynamic>{
    'id': 'p1',
    'name': 'Sabuni',
    'barcode': '6203013250040',
    'sku': 'SAB-01',
  };
  final upc = <String, dynamic>{
    'id': 'p2',
    'name': 'Juice',
    'barcode': '012345678905',
  };
  final hidden = <String, dynamic>{
    'id': 'p3',
    'name': 'Old',
    'barcode': '999',
    'isActive': false,
  };

  test('matches an EAN-13 barcode exactly', () {
    expect(posCodeMatches(soap, '6203013250040'), isTrue);
    expect(posCodeMatches(soap, '6203013250041'), isFalse);
  });

  test('matches SKU, ignoring case and spaces', () {
    expect(posCodeMatches(soap, 'sab-01'), isTrue);
    expect(posCodeMatches(soap, ' 6203013250040 '), isTrue);
  });

  test('UPC-A stored, read back as EAN-13 with a leading zero', () {
    expect(posCodeMatches(upc, '0012345678905'), isTrue);
  });

  test('empty code never matches', () {
    expect(posCodeMatches(<String, dynamic>{'barcode': ''}, ''), isFalse);
  });

  test('posFindByCode skips inactive products', () {
    final all = [soap, upc, hidden];
    expect(posFindByCode(all, '6203013250040')?['id'], 'p1');
    expect(posFindByCode(all, '999'), isNull);
  });
}
