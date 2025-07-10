import 'package:json_annotation/json_annotation.dart';

part 'page_info.g.dart';

@JsonSerializable()
class PageInfo {
  final int page;
  final int limit;
  final int itemsFound;
  final int totalPages;
  final int total_items;

  PageInfo({
    required this.page,
    required this.limit,
    required this.itemsFound,
    required this.totalPages,
    required this.total_items,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) => _$PageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PageInfoToJson(this);
}