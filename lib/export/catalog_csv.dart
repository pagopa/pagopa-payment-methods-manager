import 'dart:convert';

import '../models/payment_method.dart';
import '../models/psp_bundle_details.dart';

/// CSV con BOM UTF-8 e separatore italiano, leggibile direttamente da Excel.
class CatalogCsv {
  static const _bundleColumns = [
    'idBundle',
    'name',
    'description',
    'type',
    'touchpoint',
    'paymentType',
    'paymentAmount',
    'minPaymentAmount',
    'maxPaymentAmount',
    'idPsp',
    'pspBusinessName',
    'idChannel',
    'idBrokerPsp',
    'abi',
    'onUs',
    'cart',
    'digitalStamp',
    'digitalStampRestriction',
    'transferCategoryList',
    'validityDateFrom',
    'validityDateTo',
    'insertedDate',
    'lastUpdatedDate',
    'urlPolicyPsp',
  ];
  static const _methodColumns = [
    'payment_method_id',
    'id',
    'name',
    'description',
    'group',
    'status',
    'method_management',
    'payment_method_types',
    'user_touchpoint',
    'user_device',
    'target',
    'validity_date_from',
    'range_amount',
    'metadata',
    'payment_method_asset',
    'payment_methods_brand_assets',
  ];

  static String bundles(Iterable<PspBundleDetails> records) =>
      encode(_bundleColumns, records.map((record) => {
            ...record.toJson(),
            'validityDateFrom':
                record.validityDateFrom?.toIso8601String().split('T').first,
            'validityDateTo':
                record.validityDateTo?.toIso8601String().split('T').first,
          }));

  static String methods(Iterable<PaymentMethod> records) =>
      encode(_methodColumns, records.map((record) => record.toJson()));

  /// Mantiene liste e mappe come JSON nella cella, senza perdere lingue o valori.
  /// Gli importi restano in centesimi, come nei campi originali delle API.
  static String encode(
      List<String> columns, Iterable<Map<String, dynamic>> records) {
    final output = StringBuffer('\uFEFF');
    output.write('${columns.map(_cell).join(';')}\r\n');
    for (final record in records) {
      output.write(columns.map((column) => _cell(record[column])).join(';'));
      output.write('\r\n');
    }
    return output.toString();
  }

  static String _cell(Object? value) {
    var text = value == null
        ? ''
        : value is Map || value is List
            ? json.encode(value)
            : value.toString();
    // Le virgolette CSV non impediscono a Excel di eseguire formule:
    // neutralizziamo anche formule precedute da spazi o caratteri di controllo.
    if (RegExp(r'^[\s\u0000-\u001f]*[=+\-@]').hasMatch(text) ||
        RegExp(r'^[\t\r\n]').hasMatch(text)) {
      text = "'$text";
    }
    return '"${text.replaceAll('"', '""')}"';
  }
}
