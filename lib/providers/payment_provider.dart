// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/payment_method.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _jwt = '';
  String _host = '';
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if(_jwt.isNotEmpty) {
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
}