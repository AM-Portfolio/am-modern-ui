class MostRecentTradeDateDto {
  const MostRecentTradeDateDto({required this.date, required this.year});

  final String date;
  final int year;

  factory MostRecentTradeDateDto.fromJson(Map<String, dynamic> json) =>
      MostRecentTradeDateDto(
        date: json['date'] as String,
        year: json['year'] as int,
      );
}
