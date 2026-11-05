import 'package:flutter_test/flutter_test.dart';
import 'package:payment_methods_manager/export/catalog_csv.dart';
import 'package:payment_methods_manager/models/payment_method.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';

void main() {
  test('CSV uses UTF-8 BOM, semicolons, CRLF and escapes special characters',
      () {
    final csv = CatalogCsv.encode([
      'name',
      'description'
    ], [
      {'name': 'Caffe\u00e8; "PSP"', 'description': 'prima\nseconda'},
    ]);
    expect(
        csv,
        '\uFEFF"name";"description"\r\n'
        '"Caffe\u00e8; ""PSP""";"prima\nseconda"\r\n');
  });

  test('CSV neutralizes spreadsheet formulas including leading whitespace', () {
    for (final value in [
      '=1+1',
      '+cmd',
      '-2+3',
      '@SUM(A1)',
      '  =1',
      '\t=1',
      '\r=1'
    ]) {
      expect(
          CatalogCsv.encode([
            'value'
          ], [
            {'value': value}
          ]),
          contains('"\'$value"'));
    }
  });

  test(
      'zero and false remain explicit, null stays empty, maps retain languages',
      () {
    final csv = CatalogCsv.bundles([
      PspBundleDetails(idBundle: 'id', paymentAmount: 0, onUs: false),
    ]);
    expect(csv, contains('"0"'));
    expect(csv, contains('"false"'));
    expect(csv, isNot(contains('null')));
    final methods = CatalogCsv.methods([
      PaymentMethod(
          paymentMethodId: 'id',
          name: {'IT': 'Nome', 'EN': 'Name'},
          userTouchpoint: ['IO', 'CHECKOUT']),
    ]);
    expect(methods, contains('"{""IT"":""Nome"",""EN"":""Name""}"'));
    expect(methods, contains('"[""IO"",""CHECKOUT""]"'));
  });

  test('empty export includes column headers', () {
    expect(CatalogCsv.bundles([]), startsWith('\uFEFF"idBundle";'));
    expect(CatalogCsv.bundles([]).split('\r\n'), hasLength(2));
  });
}
