// lib/api/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_method.dart';

class ApiService {
  // USA IL SERVER LOCALE COME DA SPECIFICA OPENAPI
  static const String _baseUrl = 'http://localhost:8080';

  // INSERISCI QUI LA TUA API KEY
  static const String _apiKey = 'LA_TUA_API_KEY';

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    // 'Ocp-Apim-Subscription-Key': _apiKey,
  };

  // READ: Ottiene tutti i metodi di pagamento
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payment-methods'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      // La risposta dell'API per questo endpoint non è chiara.
      // Assumiamo che ritorni una lista di oggetti JSON.
      // Se la struttura è diversa (es. un oggetto che contiene la lista),
      // dovrai adattare il parsing.
      final List<dynamic> data = json.decode(response.body) as List;
      return data.map((json) => PaymentMethod.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payment methods. Status: ${response.statusCode}');
    }
  }

  // CREATE: Crea un nuovo metodo di pagamento
  Future<PaymentMethod> createPaymentMethod(PaymentMethod paymentMethod) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payment-methods'),
      headers: _headers,
      body: json.encode(paymentMethod.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // L'API potrebbe ritornare l'oggetto creato o un corpo vuoto.
      // Se ritorna l'oggetto: return PaymentMethod.fromJson(json.decode(response.body));
      return paymentMethod; // Semplifichiamo
    } else {
      throw Exception('Failed to create payment method. Status: ${response.statusCode}');
    }
  }

  // UPDATE: Aggiorna un metodo di pagamento esistente
  Future<PaymentMethod> updatePaymentMethod(String id, PaymentMethod paymentMethod) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/payment-methods/$id'),
      headers: _headers,
      body: json.encode(paymentMethod.toJson()),
    );

    if (response.statusCode == 200) {
      // Come per create, l'API potrebbe ritornare l'oggetto aggiornato.
      return paymentMethod;
    } else {
      throw Exception('Failed to update payment method. Status: ${response.statusCode}');
    }
  }

  // DELETE: Elimina un metodo di pagamento
  Future<void> deletePaymentMethod(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/payment-methods/$id'),
      headers: _headers,
    );

    // Una richiesta DELETE di successo di solito risponde con 200 (OK) o 204 (No Content).
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete payment method. Status: ${response.statusCode}');
    }
  }
}