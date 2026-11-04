import 'package:flutter/material.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';

import '../api/api_service.dart';
import '../models/payment_method.dart';
import '../models/catalog_filters.dart';

enum BundleStatusFilter { all, active, future, expired }

class ApiProvider with ChangeNotifier {
  ApiProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  bool methodsLoading = false;
  String? methodsError;
  bool detailLoading = false;
  String? detailError;
  int _bundleGeneration = 0;
  int _methodGeneration = 0;
  int _detailGeneration = 0;
  bool bundlesComplete = false;
  int bundlePagesLoaded = 0;
  int bundleTotalPages = 0;
  CatalogFilters bundleFilters = CatalogFilters();
  List<Map<String, dynamic>> ciAssociations = [];
  List<Map<String, dynamic>> selectedCiAttributes = [];
  String? selectedCiError;
  bool selectedCiLoading = false;
  bool _disposed = false;
  int _ciGeneration = 0;
  final Map<String, PspBundleDetails> _detailCache = {};

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _bundleGeneration++;
    _methodGeneration++;
    _detailGeneration++;
    _ciGeneration++;
    super.dispose();
  }

  String _jwt = '';
  String _host = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  List<PaymentMethod> _paymentMethods = [];

  List<PaymentMethod> get paymentMethods => _paymentMethods;

  List<PspBundleDetails> _bundles = [];
  PspBundleDetails? _selectedBundle;

  PspBundleDetails? get selectedBundle => _selectedBundle;
  int _currentPage = 0;
  bool _hasMore = true;

  String? _nameFilter;

  String? get nameFilter => _nameFilter;
  List<String>? _typesFilter;

  List<String>? get typesFilter => _typesFilter;
  BundleStatusFilter _statusFilter = BundleStatusFilter.all;

  BundleStatusFilter get statusFilter => _statusFilter;
  String? _pspFilter;

  String? get pspFilter => _pspFilter;

  List<PspBundleDetails> get filteredBundles {
    List<PspBundleDetails> result = List.from(_bundles);

    if (_pspFilter != null && _pspFilter!.isNotEmpty) {
      result = result.where((bundle) {
        final pspCode = bundle.idPsp?.toLowerCase() ?? '';
        final pspName = bundle.pspBusinessName?.toLowerCase() ?? pspCode;
        var filter = _pspFilter!.toLowerCase();
        return pspName.contains(filter) || pspCode.contains(filter);
      }).toList();
    }
    return result.where((bundle) {
      if (!bundleFilters.matchesBundle(bundle, DateTime.now())) return false;
      if (bundleFilters['ci'].isEmpty) return true;
      return bundle.type == 'GLOBAL' ||
          ciAssociations.any((item) => item['idBundle'] == bundle.idBundle);
    }).toList();
  }

  List<String> get uniquePspNames {
    if (_bundles.isEmpty) return [];
    final pspSet = <String>{};
    for (var bundle in _bundles) {
      if (bundle.pspBusinessName != null &&
          bundle.pspBusinessName!.isNotEmpty) {
        pspSet.add(bundle.pspBusinessName!);
      }
    }
    final pspList = pspSet.toList();
    pspList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return pspList;
  }

  void updateConfig({required String jwt, required String host}) {
    if (_jwt == jwt && _host == host) return;

    _jwt = jwt;
    _host = host;

    _apiService.setAuthToken(_jwt);
    _apiService.setHost(_host);

    _detailCache.clear();
    _methodGeneration++;
    _detailGeneration++;
    _ciGeneration++;
    _paymentMethods = [];
    _selectedBundle = null;
    selectedCiAttributes = [];
    selectedCiError = null;
    detailError = null;
    fetchMoreBundles(isRefresh: true);
    fetchPaymentMethods();
  }

  Future<void> fetchPaymentMethods() async {
    final generation = ++_methodGeneration;
    methodsLoading = true;
    methodsError = null;
    notifyListeners();

    try {
      if (_jwt.isNotEmpty) {
        final methods = await _apiService.getPaymentMethods();
        if (generation == _methodGeneration) _paymentMethods = methods;
      }
    } catch (e) {
      if (generation == _methodGeneration) methodsError = e.toString();
    } finally {
      if (generation == _methodGeneration) {
        methodsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    try {
      await _apiService.createPaymentMethod(method);
      await fetchPaymentMethods();
    } catch (e) {
      methodsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExistingPaymentMethod(
      String id, PaymentMethod method) async {
    try {
      await _apiService.updatePaymentMethod(id, method);
      await fetchPaymentMethods();
    } catch (e) {
      methodsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await _apiService.deletePaymentMethod(id);
      await fetchPaymentMethods();
    } catch (e) {
      methodsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchBundleDetails(String bundleId) async {
    final generation = ++_detailGeneration;
    detailLoading = true;
    _selectedBundle = null;
    detailError = null;
    _ciGeneration++;
    selectedCiAttributes = [];
    selectedCiError = null;
    selectedCiLoading = false;
    notifyListeners();

    try {
      final bundle = _detailCache[bundleId] ??
          await _apiService.getBundleDetails(bundleId);
      if (generation == _detailGeneration) {
        _detailCache[bundleId] = bundle;
        _selectedBundle = bundle;
      }
    } catch (e) {
      if (generation == _detailGeneration) detailError = e.toString();
    } finally {
      if (generation == _detailGeneration) {
        detailLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchMoreBundles({bool isRefresh = false}) async {
    if (!isRefresh && (_isLoading || !_hasMore)) return;
    final generation = ++_bundleGeneration;
    if (isRefresh) {
      _currentPage = 0;
      _bundles = [];
      _hasMore = true;
      _errorMessage = null;
      bundlesComplete = false;
      bundlePagesLoaded = 0;
      bundleTotalPages = 0;
      ciAssociations = [];
    }

    _isLoading = true;
    notifyListeners();

    bool? active;

    if (_statusFilter == BundleStatusFilter.active) {
      active = true;
    }

    try {
      if (bundleFilters['ci'].isNotEmpty) {
        var page = 0;
        var total = 1;
        do {
          final data = await _apiService.getMarketplaceResource(
              ['cis', bundleFilters['ci'], 'bundles'],
              page: page);
          if (generation != _bundleGeneration) return;
          ciAssociations.addAll((data['bundles'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map)));
          total = (data['pageInfo'] as Map)['totalPages'] as int;
          page++;
        } while (page < total);
      }
      do {
        final response = await _apiService.getBundles(
            page: _currentPage,
            limit: 100,
            name: _nameFilter,
            types: _typesFilter ?? ['GLOBAL', 'PUBLIC', 'PRIVATE'],
            active: active);
        if (generation != _bundleGeneration) return;
        final ids = _bundles.map((bundle) => bundle.idBundle).toSet();
        _bundles.addAll(response.bundles.where(
            (bundle) => bundle.idBundle == null || ids.add(bundle.idBundle)));
        _currentPage++;
        bundlePagesLoaded = _currentPage;
        bundleTotalPages = response.pageInfo.totalPages;
        _hasMore = _currentPage < bundleTotalPages;
        notifyListeners();
        if (generation != _bundleGeneration) return;
      } while (_hasMore);
      bundlesComplete = true;
    } catch (e) {
      if (generation == _bundleGeneration) _errorMessage = e.toString();
    } finally {
      if (generation == _bundleGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void stopBundleSearch() {
    _bundleGeneration++;
    _isLoading = false;
    _hasMore = false;
    bundlesComplete = false;
    notifyListeners();
  }

  void applyBundleFilters(Map<String, String> values) {
    bundleFilters = CatalogFilters(values);
    _nameFilter = values['name'];
    _typesFilter = (values['type'] ?? '').isEmpty ? null : [values['type']!];
    _pspFilter = values['psp'];
    _statusFilter = switch (values['status']) {
      'active' => BundleStatusFilter.active,
      'future' => BundleStatusFilter.future,
      'expired' => BundleStatusFilter.expired,
      _ => BundleStatusFilter.all,
    };
    fetchMoreBundles(isRefresh: true);
  }

  Future<void> fetchCiAttributes(String ci, String bundleId) async {
    selectedCiLoading = true;
    selectedCiError = null;
    selectedCiAttributes = [];
    final generation = ++_ciGeneration;
    notifyListeners();
    try {
      final data = await _apiService.getMarketplaceResource(
          ['cis', ci, 'bundles', bundleId, 'attributes']);
      if (generation != _ciGeneration) return;
      selectedCiAttributes = (data['attributes'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      if (generation == _ciGeneration) selectedCiError = e.toString();
    } finally {
      if (generation == _ciGeneration) {
        selectedCiLoading = false;
        notifyListeners();
      }
    }
  }

  void setFilters(
      {String? name,
      List<String>? types,
      BundleStatusFilter? status,
      String? psp}) {
    final bool apiFiltersChanged = _nameFilter != name ||
        _typesFilter.toString() != (types ?? []).toString() ||
        _statusFilter != (status ?? BundleStatusFilter.all);

    final bool pspFilterChanged = _pspFilter != psp;

    _nameFilter = name;
    _typesFilter = types;
    _statusFilter = status ?? BundleStatusFilter.all;
    _pspFilter = psp;

    if (apiFiltersChanged) {
      fetchMoreBundles(isRefresh: true);
    } else if (pspFilterChanged) {
      notifyListeners();
    }
  }
}
