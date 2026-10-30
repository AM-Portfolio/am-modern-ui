import '../../domain/entities/calendar_latest_activity.dart';

/// DTO for GET /v1/trades/calendar/latest-activity
class CalendarLatestActivityDto {
  const CalendarLatestActivityDto({
    required this.lastTradeDate,
    required this.year,
    required this.month,
  });

  factory CalendarLatestActivityDto.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['lastTradeDate'];
    final DateTime date;
    if (dateRaw is String) {
      date = DateTime.parse(dateRaw);
    } else {
      throw FormatException('Missing lastTradeDate in latest-activity response');
    }

    return CalendarLatestActivityDto(
      lastTradeDate: date,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
    );
  }

  final DateTime lastTradeDate;
  final int year;
  final int month;

  CalendarLatestActivity toEntity() => CalendarLatestActivity(
        lastTradeDate: lastTradeDate,
        year: year,
        month: month,
      );

  Map<String, dynamic> toJson() => {
        'lastTradeDate':
            '${lastTradeDate.year}-${lastTradeDate.month.toString().padLeft(2, '0')}-${lastTradeDate.day.toString().padLeft(2, '0')}',
        'year': year,
        'month': month,
      };
}
