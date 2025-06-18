import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shiftly/db/database_helper.dart';
import 'package:shiftly/models/employee.dart';
import 'package:shiftly/screens/add_employee_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  late DateTime _currentWeekStart;
  late DateTime _currentWeekEnd;
  final ScrollController _horizontalController = ScrollController();
  List<Employee> _employees = [];
  List<Map<String, dynamic>> _shiftTimings = [];
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();

    // Calendar-related initializations
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 365));
    _lastDay = DateTime.now().add(const Duration(days: 365));
    _calculateWeekRange(_selectedDay);

    // Load shift data or employees
    _loadData();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _calculateWeekRange(DateTime date) {
    _currentWeekStart = date.subtract(Duration(days: date.weekday - 1));
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
  }

  Future<void> _loadData() async {
    final employees = await _dbHelper.getEmployees();
    final weekStart = _currentWeekStart.millisecondsSinceEpoch;
    final shiftTimings = await _dbHelper.getShiftsForWeek(weekStart);

    setState(() {
      _employees = employees.map((e) => Employee.fromMap(e)).toList();
      _shiftTimings = shiftTimings;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _calculateWeekRange(selectedDay);
      _showCalendar = false;
      _loadData();
    });
  }

  void _onWeekChanged(DateTime startOfWeek) {
    setState(() {
      _calculateWeekRange(startOfWeek);
      _loadData();
    });
  }

  void _showShiftDialog(int employeeId, String day) async {
    final employee = _employees.firstWhere((e) => e.employeeId == employeeId);
    final weekStart = _currentWeekStart.millisecondsSinceEpoch;

    // Find existing shift for this employee and day
    final existingShift = _shiftTimings.firstWhere(
      (st) =>
          st['employee_id'] == employeeId &&
          st['day'] == day.toLowerCase() &&
          st['week_start'] == weekStart,
      orElse: () => {},
    );

    String? shiftName = existingShift['shift_name'];
    String? startTimeStr = existingShift['start_time'];
    String? endTimeStr = existingShift['end_time'];
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if (startTimeStr != null && startTimeStr.contains(':')) {
      final parts = startTimeStr.split(':');
      if (parts.length == 2) {
        startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    if (endTimeStr != null && endTimeStr.contains(':')) {
      final parts = endTimeStr.split(':');
      if (parts.length == 2) {
        endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    final shiftNameController = TextEditingController(text: shiftName);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${employee.name} - ${day.toUpperCase()}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Shift Name'),
                    controller: shiftNameController,
                    onChanged: (value) => shiftName = value,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      startTime != null
                          ? 'Start Time: ${startTime?.format(context) ?? 'Select Start Time'}'
                          : 'Select Start Time',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          startTime = picked;
                          startTimeStr =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      endTime != null
                          ? 'End Time: ${endTime?.format(context) ?? 'Select End Time'}'
                          : 'Select End Time',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          endTime = picked;
                          endTimeStr =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  onPressed: () async {
                    if ((shiftNameController.text).trim().isNotEmpty) {
                      await _dbHelper.insertOrUpdateShift(
                        employeeId: employeeId,
                        day: day.toLowerCase(),
                        weekStart: weekStart,
                        shiftName: shiftNameController.text.trim(),
                        startTime: startTimeStr ?? '',
                        endTime: endTimeStr ?? '',
                      );
                      await _loadData();
                      if (!mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _getShiftForEmployeeDay(int employeeId, String day) {
    try {
      final shift = _shiftTimings.firstWhere(
        (st) =>
            st['employee_id'] == employeeId && st['day'] == day.toLowerCase(),
      );

      final shiftName = shift['shift_name']?.toString();
      final startTime = shift['start_time']?.toString();
      final endTime = shift['end_time']?.toString();

      if (shiftName == null) return null;

      if (startTime != null &&
          startTime.isNotEmpty &&
          endTime != null &&
          endTime.isNotEmpty) {
        return '$shiftName|$startTime-$endTime';
      } else {
        return shiftName;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shiftly', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEmployeeScreen(),
                ),
              ).then(
                (_) => _loadData(),
              ); // Refresh when returning from AddEmployeeScreen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Navigation
          Container(
            color: Colors.red[50],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    _onWeekChanged(
                      _currentWeekStart.subtract(const Duration(days: 7)),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCalendar = !_showCalendar;
                    });
                  },
                  child: Text(
                    '${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d').format(_currentWeekEnd)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    _onWeekChanged(
                      _currentWeekStart.add(const Duration(days: 7)),
                    );
                  },
                ),
              ],
            ),
          ),
          // Calendar
          if (_showCalendar)
            TableCalendar(
              firstDay: _firstDay,
              lastDay: _lastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarFormat: CalendarFormat.week,
              headerVisible: false,
              availableCalendarFormats: const {CalendarFormat.week: 'Week'},
              startingDayOfWeek: StartingDayOfWeek.monday,
            ),
          // Shift Table
          Expanded(child: _buildShiftTable()),
        ],
      ),
    );
  }

  Widget _buildShiftTable() {
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateFormat = DateFormat('d');

    return Column(
      children: [
        // Header Row
        SizedBox(
          height: 50.0, // Changed to double
          child: Row(
            children: [
              // Fixed employee header
              Container(
                width: 120.0, // Changed to double
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: const Text(
                  'Employee',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Scrollable days header
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: 100.0 * days.length, // Changed to double
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: List.generate(days.length, (index) {
                        final dayDate = _currentWeekStart.add(
                          Duration(days: index),
                        );
                        return SizedBox(
                          // Added SizedBox for explicit width
                          width: 100.0, // Changed to double
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                days[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(dateFormat.format(dayDate)),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Employee Rows
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: _employees.map((employee) {
                return SizedBox(
                  height: 60.0, // Changed to double
                  child: Row(
                    children: [
                      // Fixed employee name column
                      Container(
                        width: 120.0, // Changed to double
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                        ), // Changed to double
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(employee.name),
                      ),

                      // Scrollable days columns
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Container(
                            width: 100.0 * days.length, // Changed to double
                            child: Row(
                              children: List.generate(days.length, (dayIndex) {
                                final day = days[dayIndex];
                                final shift = _shiftTimings.firstWhere(
                                  (st) =>
                                      st['employee_id'] ==
                                          employee.employeeId &&
                                      st['day'].toString().toLowerCase() ==
                                          day.toLowerCase(),
                                  orElse: () => {},
                                );

                                final shiftName = shift['shift_name']
                                    ?.toString();
                                final startTime = shift['start_time']
                                    ?.toString();
                                final endTime = shift['end_time']?.toString();

                                return InkWell(
                                  onTap: () {
                                    _showShiftDialog(employee.employeeId!, day);
                                  },
                                  child: SizedBox(
                                    // Added SizedBox for explicit width
                                    width: 100.0, // Changed to double
                                    child: Padding(
                                      // Changed from Container with padding to SizedBox + Padding
                                      padding: const EdgeInsets.all(
                                        4.0,
                                      ), // Changed to double
                                      child:
                                          (shiftName != null &&
                                              shiftName.isNotEmpty)
                                          ? Container(
                                              padding: const EdgeInsets.all(
                                                4.0,
                                              ), // Changed to double
                                              decoration: BoxDecoration(
                                                color: Colors.red[100],
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      4.0, // Changed to double
                                                    ),
                                              ),
                                              child: Text(
                                                [
                                                  shiftName,
                                                  if (startTime != null &&
                                                      endTime != null)
                                                    '$startTime-$endTime',
                                                ].join('\n'),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12.0,
                                                ), // Changed to double
                                              ),
                                            )
                                          : const Icon(
                                              Icons.add,
                                              size: 16.0,
                                            ), // Changed to double
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
