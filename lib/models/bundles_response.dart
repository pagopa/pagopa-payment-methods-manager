import 'package:json_annotation/json_annotation.dart';
import 'page_info.dart';
import 'psp_bundle_details.dart';

part 'bundles_response.g.dart';

@JsonSerializable()
class BundlesResponse {
  final PageInfo pageInfo;
  final List<PspBundleDetails> bundles;

  BundlesResponse({required this.pageInfo, required this.bundles});

  factory BundlesResponse.fromJson(Map<String, dynamic> json) => _$BundlesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BundlesResponseToJson(this);
}