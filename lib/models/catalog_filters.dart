import 'payment_method.dart';
import 'psp_bundle_details.dart';

int parseCents(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) {
    throw const FormatException(
        'Inserire un importo positivo con massimo due decimali.');
  }
  final parts = normalized.split('.');
  final whole = parts.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (whole.length > 14) {
    throw const FormatException(
        'Importo oltre il limite di precisione del browser.');
  }
  final cents = int.parse(whole) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  if (cents > 9007199254740991) {
    throw const FormatException(
        'Importo oltre il limite di precisione del browser.');
  }
  return cents;
}

String money(int? cents) => cents == null
    ? 'N/D'
    : '${cents < 0 ? '-' : ''}${cents.abs() ~/ 100},${(cents.abs() % 100).toString().padLeft(2, '0')} EUR';

bool containsText(String? value, String query) =>
    (value ?? '').toLowerCase().contains(query.trim().toLowerCase());

class CatalogFilters {
  final Map<String, String> values;

  CatalogFilters([Map<String, String> values = const {}])
      : values = Map.unmodifiable(values);

  String operator [](String key) => values[key]?.trim() ?? '';

  bool matchesMethod(PaymentMethod method) {
    final search = this['search'];
    return (search.isEmpty ||
            containsText(method.displayName, search) ||
            containsText(method.paymentMethodId, search)) &&
        (this['touchpoint'].isEmpty ||
            (method.userTouchpoint ?? []).contains(this['touchpoint'])) &&
        (this['device'].isEmpty ||
            (method.userDevice ?? []).contains(this['device'])) &&
        (this['category'].isEmpty ||
            (method.paymentMethodTypes ?? []).contains(this['category'])) &&
        (this['management'].isEmpty ||
            method.methodManagement == this['management']) &&
        (this['status'].isEmpty || method.status == this['status']) &&
        (this['group'].isEmpty || method.group == this['group']);
  }

  bool matchesBundle(PspBundleDetails bundle, DateTime now) {
    bool flag(String key, bool? value) =>
        this[key].isEmpty || (value != null && value == (this[key] == 'true'));
    final amount = this['amount'].isEmpty ? null : parseCents(this['amount']);
    final minFee = this['minFee'].isEmpty ? null : parseCents(this['minFee']);
    final maxFee = this['maxFee'].isEmpty ? null : parseCents(this['maxFee']);
    final future = bundle.validityDateFrom != null &&
        DateUtilsForFilters.day(bundle.validityDateFrom!)
            .isAfter(DateUtilsForFilters.day(now));
    final expired = bundle.validityDateTo != null &&
        DateUtilsForFilters.day(bundle.validityDateTo!)
            .isBefore(DateUtilsForFilters.day(now));
    return (this['touchpoint'].isEmpty ||
            bundle.touchpoint == this['touchpoint']) &&
        (this['paymentType'].isEmpty ||
            bundle.paymentType == this['paymentType']) &&
        (this['psp'].isEmpty ||
            containsText(bundle.idPsp, this['psp']) ||
            containsText(bundle.pspBusinessName, this['psp'])) &&
        (this['channel'].isEmpty ||
            containsText(bundle.idChannel, this['channel'])) &&
        (this['broker'].isEmpty ||
            containsText(bundle.idBrokerPsp, this['broker'])) &&
        (this['taxonomy'].isEmpty ||
            (bundle.transferCategoryList ?? []).contains(this['taxonomy'])) &&
        (amount == null ||
            (bundle.minPaymentAmount != null &&
                bundle.maxPaymentAmount != null &&
                amount > bundle.minPaymentAmount! &&
                amount <= bundle.maxPaymentAmount!)) &&
        (minFee == null ||
            (bundle.paymentAmount != null &&
                bundle.paymentAmount! >= minFee)) &&
        (maxFee == null ||
            (bundle.paymentAmount != null &&
                bundle.paymentAmount! <= maxFee)) &&
        (this['status'] != 'future' || future) &&
        (this['status'] != 'expired' || expired) &&
        (this['status'] != 'active' || (!future && !expired)) &&
        flag('onUs', bundle.onUs) &&
        flag('cart', bundle.cart) &&
        flag('stamp', bundle.digitalStamp) &&
        flag('stampRestriction', bundle.digitalStampRestriction);
  }
}

class DateUtilsForFilters {
  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
