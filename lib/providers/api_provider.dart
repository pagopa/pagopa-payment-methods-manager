import 'package:flutter/material.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';

import '../api/api_service.dart';
import '../export/catalog_csv.dart';
import '../models/catalog_filters.dart';
import '../models/payment_method.dart';

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
  String? _selectedBundleId;
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
  int _environmentGeneration = 0;
  String? _selectedCi;
  CatalogFilters methodFilters = CatalogFilters();

  List<PaymentMethod> get filteredPaymentMethods =>
      _paymentMethods.where(methodFilters.matchesMethod).toList();
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
    _environmentGeneration++;
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

  bool get hasMoreBundles => _hasMore;

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
        var filter = _pspFilter!.trim().toLowerCase();
        return pspName.contains(filter) || pspCode.contains(filter);
      }).toList();
    }
    return result
        .where((bundle) => _matchesBundle(
            bundle, bundleFilters, ciAssociations, DateTime.now()))
        .toList();
  }

  // Lista ed export condividono la stessa selezione locale, inclusa l'eccezione
  // GLOBAL: l'assenza di un'adesione ente non ne implica la non applicabilita.
  bool _matchesBundle(PspBundleDetails bundle, CatalogFilters filters,
          List<Map<String, dynamic>> associations, DateTime now) =>
      filters.matchesBundle(bundle, now) &&
      (filters['ci'].isEmpty ||
          bundle.type == 'GLOBAL' ||
          associations.any((item) => item['idBundle'] == bundle.idBundle));

  void applyMethodFilters(Map<String, String> values) {
    methodFilters = CatalogFilters(values);
    notifyListeners();
  }

  /// Fotografa filtri e ambiente al click. Legge tutte le pagine separatamente
  /// dall'infinite scroll, senza cambiare posizione, record o filtri della lista.
  Future<String> exportBundlesCsv() async {
    final filters = bundleFilters;
    final name = _nameFilter;
    final types =
        List<String>.of(_typesFilter ?? ['GLOBAL', 'PUBLIC', 'PRIVATE']);
    final psp = _pspFilter;
    final active = _statusFilter == BundleStatusFilter.active ? true : null;
    final generation = _environmentGeneration;
    final now = DateTime.now();
    final associations = <Map<String, dynamic>>[];
    void checkEnvironment() {
      if (_disposed || generation != _environmentGeneration) {
        throw StateError('Ambiente cambiato durante l\'export. Riprovare.');
      }
    }

    if (filters['ci'].isNotEmpty) {
      var page = 0;
      var totalPages = 1;
      do {
        final response = await _apiService.getMarketplaceResource(
            ['cis', filters['ci'], 'bundles'],
            page: page);
        checkEnvironment();
        associations.addAll((response['bundles'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map)));
        totalPages = (response['pageInfo'] as Map)['totalPages'] as int;
        page++;
      } while (page < totalPages);
    }
    final records = <PspBundleDetails>[];
    final ids = <String>{};
    var page = 0;
    var totalPages = 1;
    do {
      final response = await _apiService.getBundles(
          page: page, limit: 100, name: name, types: types, active: active);
      checkEnvironment();
      for (final bundle in response.bundles) {
        if ((psp == null ||
                psp.trim().isEmpty ||
                containsText(bundle.idPsp, psp) ||
                containsText(bundle.pspBusinessName, psp)) &&
            _matchesBundle(bundle, filters, associations, now) &&
            (bundle.idBundle == null || ids.add(bundle.idBundle!))) {
          records.add(bundle);
        }
      }
      totalPages = response.pageInfo.totalPages;
      page++;
    } while (page < totalPages);
    // Un errore intermedio viene propagato: non generiamo mai un CSV parziale.
    return CatalogCsv.bundles(records);
  }

  Future<String> exportPaymentMethodsCsv() async {
    if (methodsLoading || methodsError != null) {
      throw StateError('Attendere il caricamento completo dei metodi.');
    }
    return CatalogCsv.methods(filteredPaymentMethods);
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

    final bundleId = _selectedBundleId;
    final ci = _selectedCi;
    _jwt = jwt;
    _host = host;
    _environmentGeneration++;

    _apiService.setAuthToken(_jwt);
    _apiService.setHost(_host);

    _detailCache.clear();
    _methodGeneration++;
    _detailGeneration++;
    _ciGeneration++;
    _paymentMethods = [];
    _selectedBundle = null;
    detailLoading = false;
    selectedCiLoading = false;
    selectedCiAttributes = [];
    selectedCiError = null;
    detailError = null;
    fetchMoreBundles(isRefresh: true);
    fetchPaymentMethods();
    if (bundleId != null) {
      fetchBundleDetails(bundleId);
      if (ci != null && ci.isNotEmpty) fetchCiAttributes(ci, bundleId);
    }
  }

  Future<void> fetchPaymentMethods() async {
    final generation = ++_methodGeneration;
    methodsLoading = true;
    methodsError = null;
    notifyListeners();

    try {
      final methods = await _apiService.getPaymentMethods();
      if (generation == _methodGeneration) _paymentMethods = methods;
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
    _selectedBundleId = bundleId;
    _selectedCi = null;
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
    _errorMessage = null;
    notifyListeners();
    final previousMatchCount = filteredBundles.length;

    bool? active;

    if (_statusFilter == BundleStatusFilter.active) {
      active = true;
    }

    try {
      if (isRefresh && bundleFilters['ci'].isNotEmpty) {
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
      // Ogni scroll carica un nuovo gruppo di risultati. Le pagine escluse dai
      // filtri locali vengono saltate finche arriva un match o finiscono i dati.
      do {
        final response = await _apiService.getBundles(
            page: _currentPage,
            limit: 20,
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
      } while (_hasMore && filteredBundles.length == previousMatchCount);
      bundlesComplete = !_hasMore;
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
    final name = bundleFilters['name'];
    _nameFilter = name.isEmpty ? null : name;
    final type = bundleFilters['type'];
    _typesFilter = type.isEmpty ? null : [type];
    final psp = bundleFilters['psp'];
    _pspFilter = psp.isEmpty ? null : psp;
    _statusFilter = switch (bundleFilters['status']) {
      'active' => BundleStatusFilter.active,
      'future' => BundleStatusFilter.future,
      'expired' => BundleStatusFilter.expired,
      _ => BundleStatusFilter.all,
    };
    fetchMoreBundles(isRefresh: true);
  }

  Future<void> fetchCiAttributes(String ci, String bundleId) async {
    _selectedCi = ci;
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
