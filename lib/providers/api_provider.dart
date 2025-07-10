import 'package:flutter/material.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';

import '../api/api_service.dart';
import '../models/payment_method.dart';

enum BundleStatusFilter { all, active, future, expired }

class ApiProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

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
    print(_bundles.length);
    List<PspBundleDetails> result = List.from(_bundles);

    if (_pspFilter != null && _pspFilter!.isNotEmpty) {
      result = result.where((bundle) {
        final pspCode = bundle.idPsp?.toLowerCase() ?? '';
        final pspName = bundle.pspBusinessName?.toLowerCase() ?? pspCode;
        var filter = _pspFilter!.toLowerCase();
        return pspName.contains(filter);
      }).toList();
    }
    return result;
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
    print('provider ${jwt.length} ${host}');

    _jwt = jwt;
    _host = host;

    _apiService.setAuthToken(_jwt);
    _apiService.setHost(_host);

    fetchMoreBundles(isRefresh: true);
    fetchPaymentMethods();
  }

  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_jwt.isNotEmpty) {
        print('fetchPaymentMethods $_host');
        _paymentMethods = await _apiService.getPaymentMethods();
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    try {
      await _apiService.createPaymentMethod(method);
      await fetchPaymentMethods();
    } catch (e) {
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await _apiService.deletePaymentMethod(id);
      await fetchPaymentMethods();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchBundleDetails(String bundleId) async {
    _isLoading = true;
    _selectedBundle = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedBundle = await _apiService.getBundleDetails(bundleId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreBundles({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _bundles = [];
      _hasMore = true;
      _errorMessage = null;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    DateTime? validFrom;
    DateTime? expireAt;
    final now = DateTime.now();
    bool? active;

    if (_statusFilter == BundleStatusFilter.active) {
      active = true;
    } else if (_statusFilter == BundleStatusFilter.expired) {
      expireAt = now.subtract(const Duration(days: 1));
    } else if (_statusFilter == BundleStatusFilter.future) {
      validFrom = now.add(const Duration(days: 1));
    }

    try {
      final response = await _apiService.getBundles(
          page: _currentPage,
          name: _nameFilter,
          types: _typesFilter,
          validFrom: validFrom,
          expireAt: expireAt,
          active: active);
      _bundles.addAll(response.bundles);
      _currentPage++;
      _hasMore = _bundles.length <
          (response.pageInfo.total_items ?? _bundles.length + 1);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
