import 'package:json_annotation/json_annotation.dart';

part 'psp_bundle_details.g.dart';

@JsonSerializable()
class PspBundleDetails {
  final String? name;
  final String? description;
  final int? paymentAmount;
  final int? minPaymentAmount;
  final int? maxPaymentAmount;
  final String? paymentType;
  final String? touchpoint;
  final String? type;
  final List<String>? transferCategoryList;
  final DateTime? validityDateFrom;
  final DateTime? validityDateTo;
  final DateTime? insertedDate;
  final DateTime? lastUpdatedDate;
  final String? idChannel;
  final String? idPsp;
  final String? idBrokerPsp;
  final bool? digitalStamp;
  final bool? digitalStampRestriction;
  final String? pspBusinessName;
  final String? urlPolicyPsp;
  final bool? cart;
  final String? abi;
  final bool? onUs;
  final String? idBundle;

  PspBundleDetails({
    this.name,
    this.description,
    this.paymentAmount,
    this.minPaymentAmount,
    this.maxPaymentAmount,
    this.paymentType,
    this.touchpoint,
    this.type,
    this.transferCategoryList,
    this.validityDateFrom,
    this.validityDateTo,
    this.insertedDate,
    this.lastUpdatedDate,
    this.idChannel,
    this.idPsp,
    this.idBrokerPsp,
    this.digitalStamp,
    this.digitalStampRestriction,
    this.pspBusinessName,
    this.urlPolicyPsp,
    this.cart,
    this.abi,
    this.onUs,
    this.idBundle,
  });

  factory PspBundleDetails.fromJson(Map<String, dynamic> json) =>
      _$PspBundleDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$PspBundleDetailsToJson(this);
}