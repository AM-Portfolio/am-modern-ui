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

/// Optional device cache for Recent imports (server history APIs are SoT).
class RecentImportsStore {
  RecentImportsStore._();
  static final RecentImportsStore instance = RecentImportsStore._();

  static const _keyPrefix = 'am_recent_imports_v1_';
  static const _anonKey = 'am_recent_imports_v1__anon';
  static const maxEntries = 25;

  String _storageKey(String userId) {
    final id = userId.trim();
    return id.isEmpty ? _anonKey : '$_keyPrefix$id';
  }

  List<RecentImportEntry> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => RecentImportEntry.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      // Corrupt JSON — do not wipe prefs here; caller keeps existing string.
      return const [];
    }
  }

  List<RecentImportEntry> _mergeById(
    List<RecentImportEntry> newerFirst,
    List<RecentImportEntry> older,
  ) {
    final seen = <String>{};
    final out = <RecentImportEntry>[];
    for (final e in [...newerFirst, ...older]) {
      if (e.id.isEmpty || seen.contains(e.id)) continue;
      seen.add(e.id);
      out.add(e);
      if (out.length >= maxEntries) break;
    }
    return out;
  }

  Future<List<RecentImportEntry>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(userId);
    final raw = prefs.getString(key);
    var items = _decodeList(raw);

    // Migrate anon → real user once we have an id (and clear anon).
    final id = userId.trim();
    if (id.isNotEmpty) {
      final anonRaw = prefs.getString(_anonKey);
      final anonItems = _decodeList(anonRaw);
      if (anonItems.isNotEmpty) {
        items = _mergeById(items, anonItems);
        await prefs.setString(
          key,
          jsonEncode(items.map((e) => e.toJson()).toList()),
        );
        await prefs.remove(_anonKey);
      }
    }

    // If decode failed but raw exists, leave raw untouched and return [].
    // Next successful prepend will still read raw via merge path below.
    if (items.isEmpty && raw != null && raw.isNotEmpty) {
      // Attempt salvage: raw may be valid JSON with empty maps — already handled.
      return const [];
    }
    return items;
  }

  /// Replace the whole cache with a server-fetched list (newest first).
  Future<void> replaceAll(String userId, List<RecentImportEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(userId);
    final next = entries.take(maxEntries).toList();
    await prefs.setString(
      key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<RecentImportEntry>> prepend(
    String userId,
    RecentImportEntry entry,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(userId);
    final raw = prefs.getString(key);
    var current = _decodeList(raw);

    // If decode failed, try not to destroy the previous blob: merge entry alone
    // only when raw is empty/corrupt-empty; otherwise keep what we could parse.
    if (current.isEmpty && raw != null && raw.isNotEmpty) {
      // Corrupt — start fresh with this entry rather than wiping then losing
      // ability to recover; still write a valid list so UI works going forward.
      current = const [];
    }

    // Also pull anon history when writing under a real user.
    final id = userId.trim();
    if (id.isNotEmpty) {
      final anonItems = _decodeList(prefs.getString(_anonKey));
      current = _mergeById(current, anonItems);
      if (anonItems.isNotEmpty) {
        await prefs.remove(_anonKey);
      }
    }

    final next = _mergeById([entry], current);
    await prefs.setString(
      key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
    return next;
  }
}
