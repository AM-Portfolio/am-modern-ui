import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:am_design_system/am_design_system.dart';

/// Generic data-aware chat artifact: title + optional rows from [widgetParams.data].
class AiDataIntentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> widgetParams;
  final String? detailsRoute;

  const AiDataIntentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.widgetParams,
    this.detailsRoute,
  });

  List<String> _previewLines(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const [];
    final lines = <String>[];

    void addList(String key, {String? labelKey, String? valueKey}) {
      final raw = data[key];
      if (raw is! List) return;
      for (final item in raw.take(5)) {
        if (item is Map) {
          final label = item[labelKey ?? 'symbol'] ??
              item['name'] ??
              item['sector'] ??
              item['id'] ??
              item.toString();
          final value = valueKey != null
              ? item[valueKey]
              : (item['value'] ??
                  item['totalValue'] ??
                  item['percentage'] ??
                  item['pct'] ??
                  item['changePct']);
          lines.add(value != null ? '$label: $value' : '$label');
        } else {
          lines.add(item.toString());
        }
      }
    }

    addList('holdings', labelKey: 'symbol', valueKey: 'totalValue');
    addList('items', labelKey: 'symbol');
    addList('movers', labelKey: 'symbol', valueKey: 'changePct');
    addList('sectors', labelKey: 'sector', valueKey: 'percentage');
    addList('allocation', labelKey: 'sector', valueKey: 'percentage');
    addList('activities', labelKey: 'symbol', valueKey: 'type');
    addList('trades', labelKey: 'symbol', valueKey: 'side');

    if (lines.isEmpty) {
      for (final e in data.entries.take(6)) {
        if (e.value is Map || e.value is List) continue;
        lines.add('${e.key}: ${e.value}');
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final data = widgetParams['data'] as Map<String, dynamic>?;
    final lines = _previewLines(data);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data == null ? subtitle : '${lines.length} data point(s)',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (detailsRoute != null)
                IconButton(
                  tooltip: 'View details',
                  icon: Icon(Icons.open_in_new, size: 18, color: color),
                  onPressed: () => context.go(detailsRoute!),
                ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
