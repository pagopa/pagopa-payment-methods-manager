import 'package:flutter_test/flutter_test.dart';
import 'package:payment_methods_manager/models/catalog_filters.dart';
import 'package:payment_methods_manager/models/payment_method.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';

void main() {
  test('money conversion uses integer cents and preserves zero and absence',
      () {
    expect(parseCents('10,29'), 1029);
    expect(parseCents(' 1.2 '), 120);
    expect(parseCents('0'), 0);
    expect(parseCents('00001,00'), 100);
    expect(parseCents('90071992547409.91'), 9007199254740991);
    expect(() => parseCents('90071992547409.92'), throwsFormatException);
    expect(() => parseCents('99999999999999999999'), throwsFormatException);
    expect(money(0), '0,00 EUR');
    expect(money(null), 'N/D');
    expect(money(-103), '-1,03 EUR');
    for (final invalid in ['', '-1', '1.234', 'NaN', '1e3', '1,2.3']) {
      expect(() => parseCents(invalid), throwsFormatException);
    }
  });

  final method = PaymentMethod(
    paymentMethodId: 'id-1',
    name: {'IT': 'Metodo'},
    group: 'CP',
    status: 'ENABLED',
    userTouchpoint: ['IO', 'CHECKOUT_CART'],
    userDevice: ['ANDROID'],
    methodManagement: 'REDIRECT',
    paymentMethodTypes: ['CARTE'],
  );
  test('method filters combine all criteria and keep touchpoints distinct', () {
    expect(
        CatalogFilters({
          'search': 'ID-1',
          'touchpoint': 'IO',
          'device': 'ANDROID',
          'management': 'REDIRECT',
          'group': 'CP',
          'status': 'ENABLED',
          'category': 'CARTE',
        }).matchesMethod(method),
        isTrue);
    expect(CatalogFilters({'touchpoint': 'CHECKOUT'}).matchesMethod(method),
        isFalse);
    expect(CatalogFilters({'device': 'IOS'}).matchesMethod(method), isFalse);
    expect(
        CatalogFilters({'management': 'REDIRECT'})
            .matchesMethod(PaymentMethod()),
        isFalse);
    expect(CatalogFilters().matchesMethod(method), isTrue);
  });

  final bundle = PspBundleDetails(
    idPsp: 'PSP-CODE',
    pspBusinessName: 'Business Name',
    paymentAmount: 100,
    minPaymentAmount: 1000,
    maxPaymentAmount: 2000,
    transferCategoryList: ['9/01'],
    touchpoint: 'IO',
    onUs: false,
    validityDateFrom: DateTime(2026, 1, 1),
    validityDateTo: DateTime(2026, 11, 4),
  );
  final now = DateTime(2026, 11, 4, 23);
  test('bundle range uses min exclusive / max inclusive like calculator query',
      () {
    expect(
        CatalogFilters({'amount': '10'}).matchesBundle(bundle, now), isFalse);
    expect(
        CatalogFilters({'amount': '10.01'}).matchesBundle(bundle, now), isTrue);
    expect(CatalogFilters({'amount': '20'}).matchesBundle(bundle, now), isTrue);
    expect(CatalogFilters({'amount': '20.01'}).matchesBundle(bundle, now),
        isFalse);
  });
  test('PSP searches ID as well as business name; taxonomy is exact', () {
    expect(
        CatalogFilters({'psp': 'code', 'taxonomy': '9/01'})
            .matchesBundle(bundle, now),
        isTrue);
    expect(
        CatalogFilters({'psp': 'business'}).matchesBundle(bundle, now), isTrue);
    expect(CatalogFilters({'taxonomy': '9/0'}).matchesBundle(bundle, now),
        isFalse);
  });
  test('missing flags and fees do not become false or zero', () {
    expect(
        CatalogFilters({'onUs': 'false'}).matchesBundle(bundle, now), isTrue);
    expect(
        CatalogFilters({'cart': 'false'}).matchesBundle(bundle, now), isFalse);
    expect(
        CatalogFilters({'minFee': '0'}).matchesBundle(PspBundleDetails(), now),
        isFalse);
    expect(
        CatalogFilters({'minFee': '1', 'maxFee': '1'})
            .matchesBundle(bundle, now),
        isTrue);
  });
  test('date-only validity includes expiry day', () {
    expect(CatalogFilters({'status': 'active'}).matchesBundle(bundle, now),
        isTrue);
    expect(CatalogFilters({'status': 'expired'}).matchesBundle(bundle, now),
        isFalse);
    expect(
        CatalogFilters({'status': 'expired'})
            .matchesBundle(bundle, DateTime(2026, 11, 5)),
        isTrue);
  });
}
