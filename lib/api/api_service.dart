import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:payment_methods_manager/models/bundles_response.dart';
import 'package:payment_methods_manager/models/psp_bundle_details.dart';

import '../models/payment_method.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _basePath = '/afm/marketplace-auth/v1';

  String _authToken = '';
  String _host = '';

  void setAuthToken(String token) {
    _authToken = token;
  }

  void setHost(String host) {
    _host = host;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    headers['Authorization'] = 'Bearer $_authToken';
    return headers;
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _client.get(
      Uri.parse('$_host$_basePath/payment-methods'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> data =
          (decoded is String ? json.decode(decoded) : decoded) as List;
      return data.map((json) => PaymentMethod.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load payment methods. Status: ${response.statusCode}');
    }
  }

  Future<PaymentMethod> createPaymentMethod(PaymentMethod paymentMethod) async {
    final response = await _client.post(
      Uri.parse('$_host$_basePath/payment-methods'),
      headers: _headers,
      body: json.encode(paymentMethod.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return paymentMethod;
    } else {
      throw Exception(
          'Failed to create payment method. Status: ${response.statusCode}');
    }
  }

  Future<PaymentMethod> updatePaymentMethod(
      String id, PaymentMethod paymentMethod) async {
    final response = await _client.put(
      Uri.parse('$_host$_basePath/payment-methods/$id'),
      headers: _headers,
      body: json.encode(paymentMethod.toJson()),
    );

    if (response.statusCode == 200) {
      return paymentMethod;
    } else {
      throw Exception(
          'Failed to update payment method. Status: ${response.statusCode}');
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    final response = await _client.delete(
      Uri.parse('$_host$_basePath/payment-methods/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to delete payment method. Status: ${response.statusCode}');
    }
  }

  Future<BundlesResponse> getBundles({
    int page = 0,
    int limit = 20,
    String? name,
    List<String>? types,
    DateTime? validFrom,
    DateTime? expireAt,
    bool? active,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (name != null && name.isNotEmpty) {
      queryParameters['name'] = name;
    }
    if (types != null && types.isNotEmpty) {
      queryParameters['types'] = types;
    }
    if (validFrom != null) {
      queryParameters['validFrom'] = DateFormat('yyyy-MM-dd').format(validFrom);
    }
    if (expireAt != null) {
      queryParameters['expireAt'] = DateFormat('yyyy-MM-dd').format(expireAt);
    }
    if (active != null) {
      queryParameters['active'] = active.toString();
    }

    final uri = Uri.parse('$_host$_basePath/bundles')
        .replace(queryParameters: queryParameters);

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return BundlesResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load bundles. Status: ${response.statusCode}');
    }
  }

  Future<PspBundleDetails> getBundleDetails(String bundleId) async {
    final uri = Uri.parse('$_host$_basePath/bundles/$bundleId');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return PspBundleDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to load bundle details. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getMarketplaceResource(List<String> segments,
      {int? page}) async {
    final base = Uri.parse('$_host$_basePath');
    final uri = base.replace(
      pathSegments: [...base.pathSegments, ...segments],
      queryParameters: page == null ? null : {'page': '$page', 'limit': '100'},
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw Exception('Marketplace: ${response.statusCode} ($uri)');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
