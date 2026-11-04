import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payment_methods_manager/api/api_service.dart';
import 'package:payment_methods_manager/models/bundles_response.dart';
import 'package:payment_methods_manager/models/page_info.dart';
import 'package:payment_methods_manager/models/payment_method.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';
import 'package:payment_methods_manager/providers/api_provider.dart';
import 'package:payment_methods_manager/screens/Structure.dart';
import 'package:payment_methods_manager/screens/bundle_detail_screen.dart';
import 'package:payment_methods_manager/screens/bundle_list_screen.dart';
import 'package:payment_methods_manager/screens/payment_list_screen.dart';
import 'package:provider/provider.dart';

class WidgetApi extends ApiService {
  @override
  Future<List<PaymentMethod>> getPaymentMethods() async => [
        PaymentMethod(
            paymentMethodId: 'io-method',
            name: {'IT': 'IO method'},
            userTouchpoint: ['IO'],
            methodManagement: 'REDIRECT',
            status: 'ENABLED'),
        PaymentMethod(
            paymentMethodId: 'checkout-method',
            name: {'IT': 'Checkout method'},
            userTouchpoint: ['CHECKOUT'],
            methodManagement: 'ONBOARDABLE'),
      ];

  @override
  Future<BundlesResponse> getBundles({
    int page = 0,
    int limit = 20,
    String? name,
    List<String>? types,
    DateTime? validFrom,
    DateTime? expireAt,
    bool? active,
  }) async =>
      BundlesResponse(
        pageInfo: PageInfo(page: 0, limit: 100, itemsFound: 1, totalPages: 1),
        bundles: [
          PspBundleDetails(
              idBundle: 'id',
              name: 'Bundle name',
              type: 'GLOBAL',
              touchpoint: 'IO',
              paymentAmount: 100,
              minPaymentAmount: 0,
              maxPaymentAmount: 10000)
        ],
      );

  @override
  Future<PspBundleDetails> getBundleDetails(String bundleId) async =>
      throw StateError('detail failure');
}

Widget wrap(Widget child, ApiProvider provider) => ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets(
      'method filter applies and resets without losing management actions',
      (tester) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = ApiProvider(apiService: WidgetApi());
    addTearDown(provider.dispose);
    await provider.fetchPaymentMethods();
    await tester.pumpWidget(wrap(const PaymentListScreen(), provider));
    expect(find.text('Nuovo'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    await tester.tap(find.text('Filtri di ricerca'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome o ID metodo'), 'IO method');
    await tester.tap(find.text('Applica'));
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'IO method'),
        findsOneWidget);
    expect(find.text('Checkout method'), findsNothing);
    await tester.tap(find.text('Resetta'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout method'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'bundle list reports complete pagination and displays configured fee',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = ApiProvider(apiService: WidgetApi());
    addTearDown(provider.dispose);
    await tester.pumpWidget(wrap(const BundleListScreen(), provider));
    await tester.pumpAndSettle();
    expect(find.textContaining('ricerca completa'), findsOneWidget);
    expect(find.text('Bundle name'), findsOneWidget);
    expect(find.textContaining('1,00 EUR'), findsOneWidget);
    await tester.tap(find.text('Filtri di ricerca'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail failure shows error rather than infinite spinner',
      (tester) async {
    final provider = ApiProvider(apiService: WidgetApi());
    addTearDown(provider.dispose);
    await tester
        .pumpWidget(wrap(const BundleDetailScreen(bundleId: 'id'), provider));
    await tester.pumpAndSettle();
    expect(find.textContaining('detail failure'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('tabs preserve applied method filters across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = ApiProvider(apiService: WidgetApi());
    addTearDown(provider.dispose);
    await provider.fetchPaymentMethods();
    await tester.pumpWidget(wrap(const Structure(), provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metodi di Pagamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filtri di ricerca').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome o ID metodo'), 'IO method');
    await tester.tap(find.text('Applica').last);
    await tester.pumpAndSettle();
    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.text('Confronto IO / CHECKOUT'), findsNothing);
    await tester.tap(find.text('Pacchetti Commissionali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metodi di Pagamento'));
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'IO method'),
        findsOneWidget);
    expect(find.text('Checkout method'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
