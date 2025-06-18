class WeekInfo {
  final int? weekId;
  final int startDate;
  final int endDate;
  final String? tableName;

  WeekInfo({
    this.weekId,
    required this.startDate,
    required this.endDate,
    this.tableName,
  });

  Map<String, dynamic> toMap() {
    return {
      'week_id': weekId,
      'start_date': startDate,
      'end_date': endDate,
      'table_name': tableName,
    };
  }

  factory WeekInfo.fromMap(Map<String, dynamic> map) {
    return WeekInfo(
      weekId: map['week_id'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      tableName: map['table_name'],
    );
  }
}