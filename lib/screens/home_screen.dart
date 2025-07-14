import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shiftly/db/database_helper.dart';
import 'package:shiftly/models/employee.dart';
import 'subscription.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'sidbar.dart';
import 'employee_shift_screen.dart'; // Add import for new screen

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
  final ScrollController _verticalController = ScrollController();
  List<Employee> _employees = [];
  List<Map<String, dynamic>> _shiftTimings = [];
  bool _showCalendar = false;
  List<int> _selectedEmployeesForShift = [];
  bool _isLoading = true;
  int? _currentWeekId;
  final dbHelper = DatabaseHelper();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Calendar-related initializations
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 365));
    _lastDay = DateTime.now().add(const Duration(days: 365));

    // Initialize week range first
    _calculateWeekRange(_selectedDay);

    // Set up auto-backup timer for every 2 hours (for testing)
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      await DatabaseHelper().backupDatabase();
    });

    // Then load data
    _initWeekStartAndLoadData();
    _loadEmployees();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final employees = await _dbHelper.getEmployees();
    setState(() {
      _employees = employees.map((e) => Employee.fromMap(e)).toList();
    });
  }

  void _calculateWeekRange(DateTime date) {
    _currentWeekStart = date.subtract(Duration(days: date.weekday - 1));
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
  }

  void _initWeekStartAndLoadData() async {
    try {
      // Get the current week ID from database (this will create if doesn't exist)
      final weekStartMillis = await dbHelper.getCurrentWeekId();

      // Update the week range based on the database week
      final weekStartDate = DateTime.fromMillisecondsSinceEpoch(
        weekStartMillis,
      );
      _calculateWeekRange(weekStartDate);

      setState(() {
        _currentWeekId = weekStartMillis;
        _currentWeekStart = weekStartDate;
        _currentWeekEnd = weekStartDate.add(const Duration(days: 6));
        _selectedDay = weekStartDate;
        _focusedDay = weekStartDate;
      });

      await _ensureWeekAssignments();
      await _loadData();
    } catch (e) {
      print("❌ Error in _initWeekStartAndLoadData: $e");
    }
  }

  Future<void> _loadEmployeesForWeek(int weekId) async {
    final employeeMaps = await dbHelper.getEmployeesForWeek(weekId);

    final employees = employeeMaps.map((map) => Employee.fromMap(map)).toList();

    setState(() {
      _employees = employees;
    });
  }

  Future<void> _addEmployeeDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();

    // Get all employees
    final employees = await _dbHelper.getEmployees();

    // Find the highest current ID
    int nextId = 1; // Default start
    if (employees.isNotEmpty) {
      final ids = employees.map((e) => e['employee_id'] as int).toList();
      nextId = (ids.reduce((a, b) => a > b ? a : b)) + 1;
    }

    idController.text = nextId.toString(); // Set default value

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Employee', style: TextStyle(fontSize: 24)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    labelStyle: TextStyle(color: Color(0xFF9E9E9E)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                    labelStyle: TextStyle(color: Color(0xFF9E9E9E)),
                  ),
                  onChanged: (value) {
                    String capitalizeWords(String str) {
                      return str
                          .split(' ')
                          .map((word) {
                            if (word.isEmpty) return word;
                            return word[0].toUpperCase() + word.substring(1);
                          })
                          .join(' ');
                    }

                    final capitalized = capitalizeWords(value);
                    nameController.value = nameController.value.copyWith(
                      text: capitalized,
                      selection: TextSelection.collapsed(
                        offset: capitalized.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Button color (purple)
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ), // Padding
              ),
              onPressed: () async {
                final id = int.tryParse(idController.text);
                final name = nameController.text.trim();

                if (id != null && name.isNotEmpty) {
                  final exists = await _employeeIdExists(id);
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Employee ID already exists'),
                        backgroundColor: Colors.deepPurple,
                      ),
                    );
                  } else {
                    await _dbHelper.insertEmployeeWithId(id, name);
                    // Add employee to current week
                    final weekStart = _currentWeekStart.millisecondsSinceEpoch;
                    await _dbHelper.addEmployeeToWeek(id, weekStart);
                    Navigator.pop(context);
                    await _loadEmployees();
                    // Update shift table to include new employee
                    setState(() {
                      final currentSet = _selectedEmployeesForShift.toSet();
                      currentSet.add(id);
                      _selectedEmployeesForShift = currentSet.toList();
                    });
                  }
                }
              },
              child: const Text(
                'Add', // Button text
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ), // Text color (white) and font size
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _employeeIdExists(int id) async {
    final employees = await _dbHelper.getEmployees();
    return employees.any((e) => e['employee_id'] == id);
  }

  Future<void> _loadData() async {
    try {
      if (_currentWeekStart == null) return;

      final weekStart = _currentWeekStart.millisecondsSinceEpoch;
      final weekData = await _dbHelper.getEmployeesWithShiftsForWeek(weekStart);

      final employees = <Employee>[];
      final shiftTimings = <Map<String, dynamic>>[];

      for (final row in weekData) {
        final employeeId = row['employee_id'] as int;
        final employeeName = row['name'] as String;

        if (!employees.any((e) => e.employeeId == employeeId)) {
          employees.add(Employee(employeeId: employeeId, name: employeeName));
        }

        if (row['day'] != null) {
          shiftTimings.add({
            'employee_id': employeeId,
            'day': row['day'],
            'week_start': weekStart,
            'shift_name': row['shift_name'],
            'start_time': row['start_time'],
            'end_time': row['end_time'],
          });
        }
      }

      setState(() {
        _employees = employees;
        _shiftTimings = shiftTimings;
        _isLoading = false;
        // Update _selectedEmployeesForShift to include all employees for current week
        _selectedEmployeesForShift = employees
            .map((e) => e.employeeId!)
            .toList();
      });
    } catch (e, st) {
      print('Error in _loadData: $e\n$st');
      setState(() => _isLoading = false);
    }
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

  Future<void> _ensureWeekAssignments() async {
    final weekStart = _currentWeekStart.millisecondsSinceEpoch;
    final currentEmployees = await _dbHelper.getEmployeesForWeek(weekStart);

    if (currentEmployees.isEmpty) {
      // If no employees assigned to this week, check if we should copy from previous week
      final prevWeekStart = _currentWeekStart
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      final prevWeekEmployees = await _dbHelper.getEmployeesForWeek(
        prevWeekStart,
      );

      for (final employee in prevWeekEmployees) {
        await _dbHelper.addEmployeeToWeek(
          employee['employee_id'] as int,
          weekStart,
        );
      }
    }
  }

  Future<void> _onWeekChanged(DateTime startOfWeek) async {
    final newWeekStart = startOfWeek.subtract(
      Duration(days: startOfWeek.weekday - 1),
    );

    if (newWeekStart == _currentWeekStart) return;

    setState(() {
      _currentWeekStart = newWeekStart;
      _currentWeekEnd = newWeekStart.add(const Duration(days: 6));
      _selectedDay = newWeekStart;
      _focusedDay = newWeekStart;
      _isLoading = true;
    });

    try {
      await _ensureWeekAssignments();
      await _loadData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'selectedWeekStart',
        newWeekStart.millisecondsSinceEpoch,
      );
    } catch (e, st) {
      print('Error in _onWeekChanged: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteEmployeeDialog(int employeeId) async {
    final employee = _employees.firstWhere(
      (e) => e.employeeId == employeeId,
      orElse: () => Employee(employeeId: employeeId, name: 'Unknown'),
    );

    // Use exact week start (Monday) from helper
    final weekStart = _dbHelper.getStartOfWeek(_currentWeekStart);
    print('🗓️ Calculated week start timestamp (Monday): $weekStart');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Employee from This Week',
            style: TextStyle(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to remove ${employee.name} from this week\'s shift table?',
                ),
                const SizedBox(height: 8),
                const Text('(Employee will remain in your main employee list)'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepPurple[700], // Button color (purple)
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ), // Padding
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                final weekStart = _currentWeekStart.millisecondsSinceEpoch;
                await _dbHelper.removeEmployeeFromWeek(employeeId, weekStart);

                final deleted = await _dbHelper.removeEmployeeFromWeek(
                  employeeId,
                  weekStart,
                );

                print("🗑️ Removed employee $employeeId from week $weekStart");

                await _loadData();
              },
              child: const Text(
                'Remove', // Button text
                style: TextStyle(
                  color: Colors.white,
                ), // Text color (white) and font size
              ),
            ),
          ],
        );
      },
    );
  }

  void _showShiftDialog(int employeeId, String day) async {
    final employee = _employees.firstWhere((e) => e.employeeId == employeeId);
    final weekStart = _currentWeekStart.millisecondsSinceEpoch;

    final existingShift = _shiftTimings.firstWhere(
      (st) =>
          st['employee_id'] == employeeId &&
          st['day'] == day.toLowerCase() &&
          st['week_start'] == weekStart,
      orElse: () => {},
    );

    String? shiftName = existingShift['shift_name'];
    var startTimeVal = existingShift['start_time'];
    var endTimeVal = existingShift['end_time'];
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    String? startTimeStr;
    String? endTimeStr;

    if (startTimeVal != null) {
      if (startTimeVal is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(startTimeVal);
        startTimeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (startTimeVal is String) {
        startTimeStr = startTimeVal;
      }
    }

    if (endTimeVal != null) {
      if (endTimeVal is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(endTimeVal);
        endTimeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (endTimeVal is String) {
        endTimeStr = endTimeVal;
      }
    }

    if (startTimeStr != null &&
        startTimeStr.isNotEmpty &&
        startTimeStr != 'null') {
      final parts = startTimeStr.split(':');
      if (parts.length == 2) {
        startTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    if (endTimeStr != null && endTimeStr.isNotEmpty && endTimeStr != 'null') {
      final parts = endTimeStr.split(':');
      if (parts.length == 2) {
        endTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
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
              title: Text(
                '${employee.name} - ${day.toUpperCase()}',
                style: TextStyle(fontSize: 24),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Shift Name',
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                    controller: shiftNameController,
                    cursorColor: Colors.deepPurple,
                    onChanged: (value) {
                      // Capitalize first letter of each word
                      String capitalizeWords(String str) {
                        return str
                            .split(' ')
                            .map((word) {
                              if (word.isEmpty) return word;
                              return word[0].toUpperCase() + word.substring(1);
                            })
                            .join(' ');
                      }

                      final capitalized = capitalizeWords(value);
                      shiftNameController.value = shiftNameController.value
                          .copyWith(
                            text: capitalized,
                            selection: TextSelection.collapsed(
                              offset: capitalized.length,
                            ),
                          );
                      shiftName = capitalized;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      startTime != null
                          ? 'Start Time: ${startTime!.format(context)}'
                          : 'Start Time',
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
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      endTime != null
                          ? 'End Time: ${endTime!.format(context)}'
                          : 'End Time',
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
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[700],
                  ),
                  onPressed: () async {
                    final name = shiftNameController.text.trim();
                    final hasName = name.isNotEmpty;
                    final hasTime = startTime != null && endTime != null;

                    if (hasName || hasTime) {
                      int? startTimeMillis;
                      int? endTimeMillis;

                      if (hasTime) {
                        final startDateTime = DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                          startTime!.hour,
                          startTime!.minute,
                        );
                        startTimeMillis = startDateTime.millisecondsSinceEpoch;

                        final endDateTime = DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                          endTime!.hour,
                          endTime!.minute,
                        );
                        endTimeMillis = endDateTime.millisecondsSinceEpoch;
                      }

                      await _dbHelper.insertOrUpdateShift(
                        employeeId: employeeId,
                        day: day.toLowerCase(),
                        weekStart: weekStart,
                        shiftName: hasName ? name : null,
                        startTime: startTimeMillis,
                        endTime: endTimeMillis,
                      );

                      await _loadData();
                      if (!mounted) return;
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a shift name or time range.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.deepPurple),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Shiftly',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final selectedEmployees = await Navigator.push<List<int>>(
                context,
                MaterialPageRoute(
                  builder: (context) =>  ShiftlyProScreen(),
                ),
              );
              if (selectedEmployees != null) {
                await _loadData();
                setState(() {
                  // Add only newly added employees to _selectedEmployeesForShift
                  final currentSet = _selectedEmployeesForShift.toSet();
                  for (var empId in selectedEmployees) {
                    currentSet.add(empId);
                  }
                  _selectedEmployeesForShift = currentSet.toList();
                });
              }
            },
            child: Text('Go Pro', style: TextStyle(color: Colors.deepPurple, fontSize: 18)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Navigation
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 30,
                  ), // Increased size
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ), // Added padding
                  onPressed: () {
                    _onWeekChanged(
                      _currentWeekStart.subtract(const Duration(days: 7)),
                    );
                  },
                ),
                const SizedBox(width: 8), // Added spacing
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
                const SizedBox(width: 8), // Added spacing
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    size: 30,
                  ), // Increased size
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ), // Added padding
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
          // Shift Table or Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_employees.isEmpty
                      ? Stack(
                          children: [
                            _buildEmptyShiftTable(),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Your shift tracking will appear here.',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  const Text(
                                    'Tap below to begin.',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 15,
                                      ),
                                    ),
                                    onPressed: () {
                                      _showAddEmployeeDialog();
                                    },
                                    child: const Text(
                                      'Add Employee',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : _buildShiftTable()),
          ),
        ],
      ),
      floatingActionButton: _employees.isEmpty
          ? null // Don't show FAB when empty state is showing
          : FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              onPressed: () {
                _showAddEmployeeDialog();
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildEmptyShiftTable() {
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateFormat = DateFormat('d');
    const double cellWidth = 75.0;
    const double rowHeight = 50.0;
    final double tableWidth = cellWidth * days.length;

    return Opacity(
      opacity: 0.5,
      child: Row(
        children: [
          // Fixed Employee Column
          SizedBox(
            width: 100.0,
            child: Column(
              children: [
                // Employee Header
                Container(
                  height: rowHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[300],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Employee',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Empty Employee Names (No vertical divider anymore)
                Expanded(
                  child: Container(), // ← no border
                ),
              ],
            ),
          ),

          // Scrollable Shift Table
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              controller: _horizontalController,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Days Header
                      SizedBox(
                        height: rowHeight,
                        child: Row(
                          children: List.generate(days.length, (index) {
                            final dayDate = _currentWeekStart.add(
                              Duration(days: index),
                            );
                            return Container(
                              width: cellWidth,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple[300],
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  right: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    days[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(dayDate),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      // Empty Shift Cells
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTable() {
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateFormat = DateFormat('d');
    const double cellWidth = 75.0;
    const double rowHeight = 70.0;
    final today = DateTime.now();

    // Calculate todayIndex relative to _currentWeekStart
    final todayIndex = today.difference(_currentWeekStart).inDays;

    final visibleEmployees = _selectedEmployeesForShift.isEmpty
        ? _employees
        : _employees
              .where((e) => _selectedEmployeesForShift.contains(e.employeeId))
              .toList();

    return Row(
      children: [
        // Employee Name Column
        SizedBox(
          width: 100.0,
          child: Column(
            children: [
              Container(
                height: rowHeight,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                    right: BorderSide(color: Colors.grey.shade400, width: 1.5),
                  ),
                ),
                child: const Text(
                  'Employee',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _verticalController,
                  itemCount: visibleEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = visibleEmployees[index];
                    return GestureDetector(
                      onLongPress: () =>
                          _showDeleteEmployeeDialog(employee.employeeId!),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EmployeeShiftScreen(employee: employee),
                          ),
                        );
                      },
                      child: Container(
                        height: rowHeight,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? Colors.white
                              : Colors.grey.shade100,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                            right: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          employee.name
                              .split(' ')
                              .map(
                                (word) => word.isNotEmpty
                                    ? word[0].toUpperCase() + word.substring(1)
                                    : word,
                              )
                              .join(' '),
                          style: const TextStyle(fontSize: 14.0),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Shift Table
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            controller: _horizontalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: cellWidth * days.length,
                child: Column(
                  children: [
                    // Days Header
                    Stack(
                      children: [
                        Table(
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                            verticalInside: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                          columnWidths: {
                            for (int i = 0; i < days.length; i++)
                              i: FixedColumnWidth(cellWidth),
                          },
                          children: [
                            TableRow(
                              children: List.generate(days.length, (index) {
                                final dayDate = _currentWeekStart.add(
                                  Duration(days: index),
                                );
                                final isToday = DateUtils.isSameDay(
                                  dayDate,
                                  today,
                                );
                                return Container(
                                  height: rowHeight,
                                  color: isToday
                                      ? Colors.deepPurple
                                      : Colors.deepPurple,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        days[index],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateFormat.format(dayDate),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Shift Rows + Bounded Today Outline
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final totalHeight =
                              rowHeight * visibleEmployees.length;

                          return Stack(
                            children: [
                              SizedBox(
                                height: totalHeight,
                                child: ListView.builder(
                                  controller: _verticalController,
                                  itemCount: visibleEmployees.length,
                                  itemBuilder: (context, index) {
                                    final employee = visibleEmployees[index];
                                    return Table(
                                      border: TableBorder(
                                        horizontalInside: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        verticalInside: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      columnWidths: {
                                        for (int i = 0; i < days.length; i++)
                                          i: FixedColumnWidth(cellWidth),
                                      },
                                      children: [
                                        TableRow(
                                          children: List.generate(days.length, (
                                            dayIndex,
                                          ) {
                                            final day = days[dayIndex];
                                            final shift = _shiftTimings
                                                .firstWhere(
                                                  (st) =>
                                                      st['employee_id'] ==
                                                          employee.employeeId &&
                                                      st['day']
                                                              .toString()
                                                              .toLowerCase() ==
                                                          day.toLowerCase(),
                                                  orElse: () => {},
                                                );

                                            final shiftName =
                                                shift['shift_name']
                                                    ?.toString() ??
                                                '';
                                            final startTimeMillis =
                                                shift['start_time'];
                                            final endTimeMillis =
                                                shift['end_time'];

                                            String formatTime(int? millis) {
                                              if (millis == null) return '';
                                              final dt =
                                                  DateTime.fromMillisecondsSinceEpoch(
                                                    millis,
                                                  );
                                              return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                            }

                                            final startTime = formatTime(
                                              startTimeMillis,
                                            );
                                            final endTime = formatTime(
                                              endTimeMillis,
                                            );

                                            final hasName =
                                                shiftName.isNotEmpty;
                                            final hasTime =
                                                startTime.isNotEmpty &&
                                                endTime.isNotEmpty;

                                            return InkWell(
                                              onTap: () {
                                                _showShiftDialog(
                                                  employee.employeeId!,
                                                  day,
                                                );
                                              },
                                              child: Container(
                                                height: rowHeight,
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                color: index.isEven
                                                    ? Colors.white
                                                    : Colors.grey.shade100,
                                                child: (hasName || hasTime)
                                                    ? GestureDetector(
                                                        onTap: () {
                                                          _showShiftDialog(
                                                            employee
                                                                .employeeId!,
                                                            day,
                                                          );
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 4.0,
                                                                horizontal: 6.0,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4.0,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            hasName && hasTime
                                                                ? '$shiftName\n($startTime-$endTime)'
                                                                : hasName
                                                                ? shiftName
                                                                : '$startTime-$endTime',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize:
                                                                      12.5,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                          ),
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.add,
                                                        size: 16.0,
                                                        color: Colors.grey[300],
                                                      ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              // Today Column Outline — Ends Exactly After Last Employee Row
                              if (todayIndex >= 0 && todayIndex < days.length)
                                Positioned(
                                  left: todayIndex * cellWidth,
                                  top: 0,
                                  width: cellWidth,
                                  height: totalHeight,
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Color(0xFF03DAC5),
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddEmployeeDialog() async {
    final rawAllEmployees = await _dbHelper.getEmployees();
    print('DEBUG: All employees raw data: \$rawAllEmployees');
    final allEmployees = rawAllEmployees
        .map((e) => Employee.fromMap(e))
        .toList();
    print('DEBUG: All employees parsed: \$allEmployees');

    final weekStart = _currentWeekStart.millisecondsSinceEpoch;
    final rawWeekEmployees = await _dbHelper.getEmployeesForWeek(weekStart);
    print('DEBUG: Current week employees raw data: \$rawWeekEmployees');
    final currentWeekEmployees = rawWeekEmployees
        .map((e) => Employee.fromMap(e))
        .toList();
    print('DEBUG: Current week employees parsed: \$currentWeekEmployees');
    final currentWeekEmployeeIds = currentWeekEmployees
        .map((e) => e.employeeId!)
        .toSet();
    print('DEBUG: Current week employee IDs: \$currentWeekEmployeeIds');

    print(
      'DEBUG: All employee IDs: \${allEmployees.map((e) => e.employeeId).toList()}',
    );
    print('DEBUG: Current week employee IDs set: \$currentWeekEmployeeIds');
    final availableEmployees = allEmployees
        .where(
          (e) =>
              e.employeeId != null &&
              !currentWeekEmployeeIds.contains(e.employeeId),
        )
        .toList();
    print('DEBUG: Available employees for adding: \$availableEmployees');

    if (availableEmployees.isEmpty) {
      await _addEmployeeDialog();
      return;
    }

    List<int> selectedEmployeeIds = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Employees',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = availableEmployees[index];
                          final isSelected = selectedEmployeeIds.contains(
                            employee.employeeId,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.name ?? '',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        ' ${employee.employeeId?.toString().padLeft(4, '') ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  value: isSelected,
                                  activeColor: Colors.deepPurple,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedEmployeeIds.add(
                                          employee.employeeId!,
                                        );
                                      } else {
                                        selectedEmployeeIds.remove(
                                          employee.employeeId,
                                        );
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.deepPurple[700], // Button color (purple)
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ), // Padding
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );
                            if (context.mounted) {
                              await _addEmployeeDialog();
                            }
                          },
                          child: const Text(
                            'Add New', // Button text
                            style: TextStyle(
                              color: Colors.white,
                              // fontSize: 18,
                            ), // Text color (white) and font size
                          ),
                        ),

                        TextButton(
                          onPressed: selectedEmployeeIds.isEmpty
                              ? null
                              : () async {
                                  for (int empId in selectedEmployeeIds) {
                                    await _dbHelper.addEmployeeToWeek(
                                      empId,
                                      weekStart,
                                    );
                                  }

                                  final currentSet = _selectedEmployeesForShift
                                      .toSet();
                                  final newSet = selectedEmployeeIds.toSet();
                                  _selectedEmployeesForShift = currentSet
                                      .union(newSet)
                                      .toList();

                                  await _loadData();
                                  _selectedEmployeesForShift = [];

                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: Text(
                            'Add',
                            style: TextStyle(
                              color: selectedEmployeeIds.isEmpty
                                  ? Colors.grey
                                  : Colors.deepPurple,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
