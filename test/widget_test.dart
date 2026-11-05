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

class PagedWidgetApi extends WidgetApi {
  final List<int> requestedPages = [];

  @override
  Future<BundlesResponse> getBundles({
    int page = 0,
    int limit = 20,
    String? name,
    List<String>? types,
    DateTime? validFrom,
    DateTime? expireAt,
    bool? active,
  }) async {
    requestedPages.add(page);
    return BundlesResponse(
      pageInfo:
          PageInfo(page: page, limit: limit, itemsFound: 20, totalPages: 2),
      bundles: List.generate(
          20,
          (index) => PspBundleDetails(
                idBundle: '$page-$index',
                name: 'Bundle $page-$index',
                type: 'GLOBAL',
              )),
    );
  }
}

Widget wrap(Widget child, ApiProvider provider) => ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('scrolling loads the next batch without pagination controls',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = PagedWidgetApi();
    final provider = ApiProvider(apiService: api);
    addTearDown(provider.dispose);
    await tester.pumpWidget(wrap(const BundleListScreen(), provider));
    await tester.pumpAndSettle();
    expect(api.requestedPages, [0]);
    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    expect(api.requestedPages, [0, 1]);
    expect(provider.filteredBundles, hasLength(40));
    expect(find.textContaining('pagine'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment methods retain management actions', (tester) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = ApiProvider(apiService: WidgetApi());
    addTearDown(provider.dispose);
    provider.updateConfig(jwt: 'test-token', host: 'https://example.test');
    await provider.fetchPaymentMethods();
    await tester.pumpWidget(wrap(const PaymentListScreen(), provider));
    expect(find.text('Nuovo'), findsOneWidget);
    expect(find.text('Esporta CSV'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'IO method'),
        findsOneWidget);
    expect(find.text('Checkout method'), findsOneWidget);
    await tester.tap(find.text('Filtri di ricerca'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome o ID metodo'), 'IO method');
    await tester.ensureVisible(find.text('Applica'));
    await tester.tap(find.text('Applica'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout method'), findsNothing);
    expect(await provider.exportPaymentMethodsCsv(),
        isNot(contains('checkout-method')));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'bundle list displays fee and ID filter without pagination or filter summary',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = ApiProvider(apiService: WidgetApi());
    addTearDown(provider.dispose);
    await tester.pumpWidget(wrap(const BundleListScreen(), provider));
    await tester.pumpAndSettle();
    expect(find.textContaining('ricerca completa'), findsNothing);
    expect(find.textContaining('pagine'), findsNothing);
    expect(find.text('Bundle name'), findsOneWidget);
    expect(find.text('Esporta CSV'), findsOneWidget);
    expect(find.textContaining('1,00 EUR'), findsOneWidget);
    await tester.tap(find.text('Filtri di ricerca'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'ID pacchetto'), 'id');
    await tester.ensureVisible(find.text('Applica'));
    await tester.tap(find.text('Applica'));
    await tester.pumpAndSettle();
    expect(provider.bundleFilters['id'], 'id');
    expect(tester.widget<ExpansionTile>(find.byType(ExpansionTile)).subtitle,
        isNull);
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

  testWidgets('tabs preserve applied bundle filters across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = ApiProvider(apiService: WidgetApi());
    addTearDown(provider.dispose);
    await tester.pumpWidget(wrap(const Structure(), provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filtri di ricerca'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'ID pacchetto'), 'id');
    await tester.ensureVisible(find.text('Applica'));
    await tester.tap(find.text('Applica'));
    await tester.pumpAndSettle();
    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.text('Confronto IO / CHECKOUT'), findsNothing);
    await tester.tap(find.text('Metodi di Pagamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pacchetti Commissionali'));
    await tester.pumpAndSettle();
    expect(find.text('Bundle name'), findsOneWidget);
    expect(provider.bundleFilters['id'], 'id');
    expect(tester.takeException(), isNull);
  });
}
