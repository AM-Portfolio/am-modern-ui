enum IpoCalendarDisplayStatus {
  upcoming,
  listed;

  static IpoCalendarDisplayStatus fromString(String? value) {
    if (value == null) return IpoCalendarDisplayStatus.upcoming;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'listed') return IpoCalendarDisplayStatus.listed;
    return IpoCalendarDisplayStatus.upcoming;
  }

  String get label {
    switch (this) {
      case IpoCalendarDisplayStatus.listed:
        return 'LISTED';
      case IpoCalendarDisplayStatus.upcoming:
        return 'UPCOMING';
    }
  }
}

enum IpoCalendarDataFreshness {
  fresh,
  stale,
  unavailable;

  static IpoCalendarDataFreshness fromString(String? value) {
    if (value == null) return IpoCalendarDataFreshness.unavailable;
    final normalized = value.trim().toUpperCase();
    switch (normalized) {
      case 'FRESH':
        return IpoCalendarDataFreshness.fresh;
      case 'STALE':
        return IpoCalendarDataFreshness.stale;
      case 'UNAVAILABLE':
      default:
        return IpoCalendarDataFreshness.unavailable;
    }
  }
}

class IpoCalendarEntryDto {
  final String id;
  final String companyName;
  final IpoCalendarDisplayStatus status;
  final String listingDate;
  final double? listingPrice;
  final String? listingExchange;

  const IpoCalendarEntryDto({
    required this.id,
    required this.companyName,
    required this.status,
    required this.listingDate,
    this.listingPrice,
    this.listingExchange,
  });

  factory IpoCalendarEntryDto.fromJson(Map<String, dynamic> json) {
    return IpoCalendarEntryDto(
      id: json['id'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      status: IpoCalendarDisplayStatus.fromString(json['status'] as String?),
      listingDate: json['listingDate'] as String? ?? '',
      listingPrice: (json['listingPrice'] as num?)?.toDouble(),
      listingExchange: json['listingExchange'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'status': status.name.toUpperCase(),
    'listingDate': listingDate,
    'listingPrice': listingPrice,
    'listingExchange': listingExchange,
  };
}

class IpoCalendarMonthDto {
  final int year;
  final int month;
  final List<IpoCalendarEntryDto> entries;
  final IpoCalendarDataFreshness dataFreshness;
  final String? lastSuccessfulSyncAt;

  const IpoCalendarMonthDto({
    required this.year,
    required this.month,
    required this.entries,
    required this.dataFreshness,
    this.lastSuccessfulSyncAt,
  });

  factory IpoCalendarMonthDto.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? [];
    return IpoCalendarMonthDto(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      entries: rawEntries
          .map((e) => IpoCalendarEntryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      dataFreshness: IpoCalendarDataFreshness.fromString(
        json['dataFreshness'] as String?,
      ),
      lastSuccessfulSyncAt: json['lastSuccessfulSyncAt'] as String?,
    );
  }

  /// Groups entries by their ISO listing date (`YYYY-MM-DD`).
  Map<String, List<IpoCalendarEntryDto>> get entriesByDate {
    final map = <String, List<IpoCalendarEntryDto>>{};
    for (final entry in entries) {
      if (entry.listingDate.isNotEmpty) {
        map.putIfAbsent(entry.listingDate, () => []).add(entry);
      }
    }
    return map;
  }

  /// Returns sorted distinct event date keys for this month.
  List<String> get sortedEventDates {
    final dates = entriesByDate.keys.toList()..sort();
    return dates;
  }
}
