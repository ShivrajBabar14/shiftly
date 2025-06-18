class ShiftTiming {
  final int? rowId;
  final int employeeId;
  final String? mon;
  final String? tue;
  final String? wed;
  final String? thu;
  final String? fri;
  final String? sat;
  final String? sun;

  ShiftTiming({
    this.rowId,
    required this.employeeId,
    this.mon,
    this.tue,
    this.wed,
    this.thu,
    this.fri,
    this.sat,
    this.sun,
  });

  Map<String, dynamic> toMap() {
    return {
      'row_id': rowId,
      'employee_id': employeeId,
      'mon': mon,
      'tue': tue,
      'wed': wed,
      'thu': thu,
      'fri': fri,
      'sat': sat,
      'sun': sun,
    };
  }

  factory ShiftTiming.fromMap(Map<String, dynamic> map) {
    return ShiftTiming(
      rowId: map['row_id'],
      employeeId: map['employee_id'],
      mon: map['mon'],
      tue: map['tue'],
      wed: map['wed'],
      thu: map['thu'],
      fri: map['fri'],
      sat: map['sat'],
      sun: map['sun'],
    );
  }
}