import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One Recent Imports row (mailbox or upload), persisted per user.
class RecentImportEntry {
  const RecentImportEntry({
    required this.id,
    required this.source,
    required this.title,
    required this.status,
    required this.at,
    this.files = const [],
    this.detail,
    this.portfolioId,
  });

  final String id;
  /// `mailbox` | `upload`
  final String source;
  final String title;
  /// `success` | `failed` | `partial`
  final String status;
  final DateTime at;
  final List<String> files;
  final String? detail;
  final String? portfolioId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'title': title,
        'status': status,
        'at': at.toUtc().toIso8601String(),
        'files': files,
        if (detail != null && detail!.isNotEmpty) 'detail': detail,
        if (portfolioId != null && portfolioId!.isNotEmpty)
          'portfolioId': portfolioId,
      };

  factory RecentImportEntry.fromJson(Map<String, dynamic> json) {
    final filesRaw = json['files'];
    return RecentImportEntry(
      id: '${json['id'] ?? ''}',
      source: '${json['source'] ?? 'upload'}',
      title: '${json['title'] ?? 'Import'}',
      status: '${json['status'] ?? 'success'}',
      at: DateTime.tryParse('${json['at'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      files: filesRaw is List
          ? filesRaw.map((e) => '$e').where((s) => s.isNotEmpty).toList()
          : const [],
      detail: json['detail']?.toString(),
      portfolioId: json['portfolioId']?.toString(),
    );
  }

  /// Local display e.g. `13 Oct · 1:35 AM`.
  String get whenLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = at.toLocal();
    final h24 = local.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} · $h12:$min $ampm';
  }

  String get filesSummary {
    if (files.isEmpty) return source == 'mailbox' ? 'Gmail statement' : '1 file';
    if (files.length == 1) return files.first;
    return '${files.length} files';
  }
}

/// Device-local recent import history (not synced to backend).
class RecentImportsStore {
  RecentImportsStore._();
  static final RecentImportsStore instance = RecentImportsStore._();

  static const _keyPrefix = 'am_recent_imports_v1_';
  static const maxEntries = 10;

  Future<List<RecentImportEntry>> load(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$id');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => RecentImportEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<RecentImportEntry>> prepend(
    String userId,
    RecentImportEntry entry,
  ) async {
    final id = userId.trim();
    if (id.isEmpty) return [entry];
    final current = await load(id);
    final next = [entry, ...current.where((e) => e.id != entry.id)]
        .take(maxEntries)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$id',
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
    return next;
  }
}
