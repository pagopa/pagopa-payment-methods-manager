import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:payment_methods_manager/api/api_service.dart';
import 'package:payment_methods_manager/models/bundles_response.dart';
import 'package:payment_methods_manager/models/page_info.dart';
import 'package:payment_methods_manager/models/payment_method.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';
import 'package:payment_methods_manager/providers/api_provider.dart';

BundlesResponse page(int number, int total, List<PspBundleDetails> bundles) =>
    BundlesResponse(
        pageInfo: PageInfo(
            page: number,
            limit: 100,
            itemsFound: bundles.length,
            totalPages: total),
        bundles: bundles);

class StubApi extends ApiService {
  Future<BundlesResponse> Function(int, String?) loader;
  final List<List<String>?> requestedTypes = [];
  final List<String> paths = [];
  Completer<List<PaymentMethod>>? pendingMethods;
  StubApi(this.loader);

  @override
  Future<BundlesResponse> getBundles({
    int page = 0,
    int limit = 20,
    String? name,
    List<String>? types,
    DateTime? validFrom,
    DateTime? expireAt,
    bool? active,
  }) {
    requestedTypes.add(types);
    return loader(page, name);
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async =>
      pendingMethods == null ? [] : pendingMethods!.future;

  @override
  Future<PspBundleDetails> getBundleDetails(String bundleId) async =>
      PspBundleDetails(idBundle: bundleId);

  @override
  Future<Map<String, dynamic>> getMarketplaceResource(List<String> segments,
      {int? page}) async {
    paths.add(segments.join('/'));
    if (segments.last == 'attributes') {
      return {
        'attributes': [
          {
            'transferCategory': '9/01',
            'transferCategoryRelation': 'NOT_EQUAL',
            'maxPaymentAmount': 20
          }
        ]
      };
    }
    return {
      'bundles': [
        {'idBundle': 'public'}
      ],
      'pageInfo': {'totalPages': 1}
    };
  }
}

void main() {
  test(
      'local filters scan last page, deduplicate and explicitly request every type',
      () async {
    final api = StubApi((number, _) async => page(
        number,
        2,
        number == 0
            ? [PspBundleDetails(idBundle: 'first', touchpoint: 'IO')]
            : [
                PspBundleDetails(idBundle: 'first'),
                PspBundleDetails(idBundle: 'last', touchpoint: 'CHECKOUT')
              ]));
    final provider = ApiProvider(apiService: api);
    provider.applyBundleFilters({'touchpoint': 'CHECKOUT'});
    await Future<void>.delayed(Duration.zero);
    expect(provider.bundlesComplete, true);
    expect(provider.bundlePagesLoaded, 2);
    expect(provider.filteredBundles.single.idBundle, 'last');
    expect(api.requestedTypes, everyElement(['GLOBAL', 'PUBLIC', 'PRIVATE']));
    provider.dispose();
  });

  test('failure after first page retains data but marks it incomplete',
      () async {
    final api = StubApi((number, _) async {
      if (number == 1) throw StateError('failed page');
      return page(number, 2, [PspBundleDetails(idBundle: 'first')]);
    });
    final provider = ApiProvider(apiService: api);
    await provider.fetchMoreBundles(isRefresh: true);
    expect(provider.bundlesComplete, false);
    expect(provider.filteredBundles, hasLength(1));
    expect(provider.errorMessage, contains('failed page'));
    expect(provider.isLoading, false);
    provider.dispose();
  });

  test('new filter or stop discards older page responses', () async {
    final old = Completer<BundlesResponse>();
    final api = StubApi((_, name) => name == 'new'
        ? Future.value(page(0, 1, [PspBundleDetails(idBundle: 'new')]))
        : old.future);
    final provider = ApiProvider(apiService: api);
    final oldRun = provider.fetchMoreBundles(isRefresh: true);
    provider.applyBundleFilters({'name': 'new'});
    await Future<void>.delayed(Duration.zero);
    old.complete(page(0, 1, [PspBundleDetails(idBundle: 'old')]));
    await oldRun;
    expect(provider.filteredBundles.single.idBundle, 'new');
    final stopped = Completer<BundlesResponse>();
    api.loader = (_, __) => stopped.future;
    final stoppedRun = provider.fetchMoreBundles(isRefresh: true);
    provider.stopBundleSearch();
    stopped.complete(page(0, 1, [PspBundleDetails(idBundle: 'stopped')]));
    await stoppedRun;
    expect(provider.filteredBundles, isEmpty);
    expect(provider.bundlesComplete, false);
    provider.dispose();
  });

  test('method loading does not prevent independent bundle loading', () async {
    final api = StubApi((number, _) async => page(number, 0, []));
    api.pendingMethods = Completer<List<PaymentMethod>>();
    final provider = ApiProvider(apiService: api);
    final methods = provider.fetchPaymentMethods();
    await provider.fetchMoreBundles(isRefresh: true);
    expect(provider.methodsLoading, true);
    expect(provider.bundlesComplete, true);
    api.pendingMethods!.complete([]);
    await methods;
    provider.dispose();
  });

  test('CI filter retains GLOBAL and associations, never infers eligibility',
      () async {
    final api = StubApi((number, _) async => page(number, 1, [
          PspBundleDetails(idBundle: 'global', type: 'GLOBAL'),
          PspBundleDetails(idBundle: 'public', type: 'PUBLIC'),
          PspBundleDetails(idBundle: 'private', type: 'PRIVATE'),
        ]));
    final provider = ApiProvider(apiService: api);
    provider.applyBundleFilters({'ci': 'CI'});
    await Future<void>.delayed(Duration.zero);
    expect(provider.filteredBundles.map((bundle) => bundle.idBundle),
        ['global', 'public']);
    await provider.fetchBundleDetails('public');
    await provider.fetchCiAttributes('CI', 'public');
    expect(provider.selectedCiAttributes.single['transferCategoryRelation'],
        'NOT_EQUAL');
    expect(api.paths, contains('cis/CI/bundles/public/attributes'));
    provider.dispose();
  });

  test('missing total_items is supported by marketplace response model', () {
    final result = BundlesResponse.fromJson({
      'bundles': [],
      'pageInfo': {'page': 0, 'limit': 100, 'itemsFound': 0, 'totalPages': 0},
    });
    expect(result.pageInfo.total_items, isNull);
  });

  test('HTTP catalog handles raw array and JSON string; query types repeat',
      () async {
    for (final encoded in [false, true]) {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/bundles')) {
          expect(request.url.queryParametersAll['types'],
              ['GLOBAL', 'PUBLIC', 'PRIVATE']);
          return http.Response(
              '{"bundles":[],"pageInfo":{"page":0,"limit":100,"itemsFound":0,"totalPages":0}}',
              200);
        }
        final body = json.encode([
          {
            'payment_method_id': 'id',
            'user_touchpoint': ['IO'],
            'method_management': 'REDIRECT'
          }
        ]);
        return http.Response(encoded ? json.encode(body) : body, 200);
      });
      final api = ApiService(client: client);
      expect(
          (await api.getPaymentMethods()).single.methodManagement, 'REDIRECT');
      await api.getBundles(types: ['GLOBAL', 'PUBLIC', 'PRIVATE']);
      client.close();
    }
  });
}
