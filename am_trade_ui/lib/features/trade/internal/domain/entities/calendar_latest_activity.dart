/// Latest trade activity used to open the calendar on the right year/month.
class CalendarLatestActivity {
  const CalendarLatestActivity({
    required this.lastTradeDate,
    required this.year,
    required this.month,
  });

  final DateTime lastTradeDate;
  final int year;
  final int month;
}
