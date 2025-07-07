// lib/models/payment_method.dart
import 'dart:convert';
import 'package:intl/intl.dart';

// Helper per estrarre la lingua principale per la UI
String extractDisplayLanguage(Map<String, String>? langMap, {String langCode = 'IT'}) {
  if (langMap == null || langMap.isEmpty) return 'N/A';
  return langMap[langCode] ?? langMap.values.first;
}

class FeeRange {
  final int min;
  final int max;

  FeeRange({required this.min, required this.max});

  factory FeeRange.fromJson(Map<String, dynamic> json) {
    return FeeRange(min: json['min'] ?? 0, max: json['max'] ?? 0);
  }

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}

class PaymentMethod {
  String? id;
  String? group;
  Map<String, String>? name;
  Map<String, String>? description;
  String? status;
  List<String>? target;
  Map<String, String>? metadata;
  String? paymentMethodId;
  List<String>? userTouchpoint;
  List<String>? userDevice;
  DateTime? validityDateFrom;
  FeeRange? rangeAmount;
  String? paymentMethodAsset;
  String? methodManagement;
  Map<String, String>? paymentMethodsBrandAssets;

  PaymentMethod({
    this.id,
    this.group,
    this.name,
    this.description,
    this.status,
    this.target,
    this.metadata,
    this.paymentMethodId,
    this.userTouchpoint,
    this.userDevice,
    this.validityDateFrom,
    this.rangeAmount,
    this.paymentMethodAsset,
    this.methodManagement,
    this.paymentMethodsBrandAssets,
  });

  // Nome per la visualizzazione nella UI
  String get displayName => extractDisplayLanguage(name);

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      group: json['group'],
      name: json['name'] != null ? Map<String, String>.from(json['name']) : null,
      description: json['description'] != null ? Map<String, String>.from(json['description']) : null,
      status: json['status'],
      target: json['target'] != null ? List<String>.from(json['target']) : null,
      metadata: json['metadata'] != null ? Map<String, String>.from(json['metadata']) : null,
      paymentMethodId: json['payment_method_id'],
      userTouchpoint: json['user_touchpoint'] != null ? List<String>.from(json['user_touchpoint']) : null,
      userDevice: json['user_device'] != null ? List<String>.from(json['user_device']) : null,
      validityDateFrom: json['validity_date_from'] != null ? DateTime.parse(json['validity_date_from']) : null,
      rangeAmount: json['range_amount'] != null ? FeeRange.fromJson(json['range_amount']) : FeeRange(min: 0, max: 0),
      paymentMethodAsset: json['payment_method_asset'],
      methodManagement: json['method_management'],
      paymentMethodsBrandAssets: json['payment_methods_brand_assets'] != null ? Map<String, String>.from(json['payment_methods_brand_assets']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    if (group != null) data['group'] = group;
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (status != null) data['status'] = status;
    if (target != null) data['target'] = target;
    if (metadata != null) data['metadata'] = metadata;
    if (paymentMethodId != null) data['payment_method_id'] = paymentMethodId;
    if (userTouchpoint != null) data['user_touchpoint'] = userTouchpoint;
    if (userDevice != null) data['user_device'] = userDevice;
    if (validityDateFrom != null) {
      data['validity_date_from'] = DateFormat('yyyy-MM-dd').format(validityDateFrom!);
    }
    if (rangeAmount != null) data['range_amount'] = rangeAmount!.toJson();
    if (paymentMethodAsset != null) data['payment_method_asset'] = paymentMethodAsset;
    if (methodManagement != null) data['method_management'] = methodManagement;
    if (paymentMethodsBrandAssets != null) data['payment_methods_brand_assets'] = paymentMethodsBrandAssets;
    return data;
  }
}