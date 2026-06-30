import 'package:am_dashboard_ui/domain/models/activity_item.dart';

class RecentActivityResponse {
  const RecentActivityResponse({
    required this.items,
    this.page = 0,
    this.size = 10,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  final List<ActivityItem> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  factory RecentActivityResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => ActivityItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ActivityItem>[];

    return RecentActivityResponse(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 10,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );
  }
}
