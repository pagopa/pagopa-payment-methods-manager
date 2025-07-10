// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';
import '../api/api_service.dart';
import '../models/payment_method.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _jwt = '';
  String _host = '';

  List<PaymentMethod> _paymentMethods = [];
  List<PaymentMethod> get paymentMethods => _paymentMethods;

  List<PspBundleDetails> _bundles = [];
  List<PspBundleDetails> get bundles => _bundles;

  PspBundleDetails? _selectedBundle;
  PspBundleDetails? get selectedBundle => _selectedBundle;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void updateConfig({required String jwt, required String host}) {
    if (_jwt != jwt || _host != host) {
      print('PaymentProvider: Configurazione aggiornata. JWT: $jwt, Host: $host');
      _jwt = jwt;
      _host = host;

      _apiService.setAuthToken(_jwt);
      _apiService.setHost(_host);

      fetchPaymentMethods();

      notifyListeners();
    }
  }

  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if(_jwt.isNotEmpty || _host.isEmpty) {
        _paymentMethods = await _apiService.getPaymentMethods();
        _errorMessage = null;
      }
      print('PaymentProvider: Fetched ${_paymentMethods.length} payment methods.');
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
      // Ricarica la lista per mostrare il nuovo elemento
      await fetchPaymentMethods();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      // Rilancia l'eccezione per farla gestire dalla UI se necessario
      rethrow;
    }
  }

  Future<void> updateExistingPaymentMethod(String id, PaymentMethod method) async {
    try {
      await _apiService.updatePaymentMethod(id, method);
      // Ricarica la lista per mostrare l'elemento aggiornato
      await fetchPaymentMethods();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // NUOVO METODO PER IL DELETE
  Future<void> deletePaymentMethod(String id) async {
    try {
      await _apiService.deletePaymentMethod(id);
      // Rimuovi l'elemento dalla lista locale per un aggiornamento istantaneo della UI,
      // oppure ricarica tutto con fetchPaymentMethods() per la massima consistenza.
      // Scegliamo la seconda opzione per semplicità e robustezza.
      await fetchPaymentMethods();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }


  Future<void> fetchBundles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getGlobalBundles();
      _bundles = response.bundles;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
}