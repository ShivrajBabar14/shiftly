import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/db/database_helper.dart';
import 'package:shiftly/models/employee.dart';

class EmployeeShiftScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeShiftScreen({Key? key, required this.employee}) : super(key: key);

  @override
  State<EmployeeShiftScreen> createState() => _EmployeeShiftScreenState();
}

class _EmployeeShiftScreenState extends State<EmployeeShiftScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late DateTime _currentWeekStart;
  late DateTime _currentWeekEnd;
  bool _isLoading = true;
  List<Map<String, dynamic>> _shiftData = [];

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _dbHelper.getStartOfWeek(DateTime.now());
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
    _loadShiftData();
  }

  void _loadShiftData() async {
    setState(() {
      _isLoading = true;
    });
    final weekStartMillis = _currentWeekStart.millisecondsSinceEpoch;
    final data = await _dbHelper.getShiftsForEmployeeWeek(widget.employee.employeeId!, weekStartMillis);
    setState(() {
      _shiftData = data;
      _isLoading = false;
    });
  }

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
      _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
    });
    _loadShiftData();
  }

  String _formatDateRange() {
    final start = DateFormat('MMM d').format(_currentWeekStart);
    final end = DateFormat('MMM d').format(_currentWeekEnd);
    return '$start - $end';
  }

  String _formatShiftTime(Map<String, dynamic> shift) {
    final shiftName = shift['shift_name'] ?? '';
    final startTimeMillis = shift['start_time'];
    final endTimeMillis = shift['end_time'];

    String formatTime(int? millis) {
      if (millis == null) return '';
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final startTime = formatTime(startTimeMillis);
    final endTime = formatTime(endTimeMillis);

    if (shiftName.isNotEmpty && startTime.isNotEmpty && endTime.isNotEmpty) {
      return '$shiftName ($startTime to $endTime)';
    } else if (shiftName.isNotEmpty) {
      return shiftName;
    } else if (startTime.isNotEmpty && endTime.isNotEmpty) {
      return '$startTime to $endTime';
    } else {
      return 'No Shift';
    }
  }

  String _dayLabel(int index) {
    final date = _currentWeekStart.add(Duration(days: index));
    return DateFormat('EEEE d').format(date);
  }

  Map<String, dynamic>? _getShiftForDay(String day) {
    return _shiftData.firstWhere(
      (shift) => shift['day'] == day.toLowerCase(),
      orElse: () => {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.deepPurple),
        title: Text(
          widget.employee.name,
          style: const TextStyle(color: Colors.deepPurple),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Week navigation
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, color: Colors.deepPurple),
                  onPressed: () => _changeWeek(-7),
                ),
                Text(
                  _formatDateRange(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, color: Colors.deepPurple),
                  onPressed: () => _changeWeek(7),
                ),
              ],
            ),
          ),
          // Table header
          Container(
            color: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Date',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Shift Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Shift data rows
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final dayName = DateFormat('EEEE').format(_currentWeekStart.add(Duration(days: index)));
                      final shift = _getShiftForDay(dayName);
                      final shiftText = shift != null ? _formatShiftTime(shift) : 'No Shift';

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  _dayLabel(index),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  shiftText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
