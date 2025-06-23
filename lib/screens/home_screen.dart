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
  final ScrollController _verticalController = ScrollController();
  List<Employee> _employees = [];
  List<Map<String, dynamic>> _shiftTimings = [];
  bool _showCalendar = false;
  List<int> _selectedEmployeesForShift = [];

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
    _verticalController.dispose();
    super.dispose();
  }

  void _calculateWeekRange(DateTime date) {
    _currentWeekStart = date.subtract(Duration(days: date.weekday - 1));
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
  }

  Future<void> _addEmployeeDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Employee', style: TextStyle(fontSize: 18)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Employee ID'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Employee Name'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
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
                    Navigator.pop(dialogContext); // ✅ closes the dialog
                    await _loadEmployees(); // refresh UI
                  }
                }
              },
              child: const Text('Add', style: TextStyle(fontSize: 18)),
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

  Future<void> _loadEmployees() async {
    final employees = await _dbHelper.getEmployees();
    setState(() {
      _employees = employees.map((e) => Employee.fromMap(e)).toList();
    });
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

  Future<void> _showDeleteEmployeeDialog(int employeeId) async {
    final employee = _employees.firstWhere((e) => e.employeeId == employeeId);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Employee from Week'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Text('Remove ${employee.name} from all shifts?'),
                const SizedBox(height: 8),
                const Text('(Employee will remain in your employee list)'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () async {
                // Delete all shift data for this employee in current week only
                await _dbHelper.removeEmployeeFromWeek(
                  employeeId,
                  _currentWeekStart.millisecondsSinceEpoch,
                );

                // Refresh data and UI
                await _loadData();

                // Optionally remove from selected list (if used for UI highlight)
                setState(() {
                  _selectedEmployeesForShift.remove(employeeId);
                });

                if (!mounted) return;
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
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
                    decoration: const InputDecoration(
                      labelText: 'Shift Name',
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                    controller: shiftNameController,
                    cursorColor: Colors.deepPurple,
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
                    if ((shiftNameController.text).trim().isNotEmpty) {
                      int startTimeMillis = 0;
                      int endTimeMillis = 0;

                      if (startTime != null) {
                        final startDateTime = DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                          startTime!.hour,
                          startTime!.minute,
                        );
                        startTimeMillis = startDateTime.millisecondsSinceEpoch;
                      }

                      if (endTime != null) {
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
                        shiftName: shiftNameController.text.trim(),
                        startTime: startTimeMillis,
                        endTime: endTimeMillis,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.deepPurple),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text(
          'Shiftly',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.deepPurple),
            onPressed: () async {
              final selectedEmployees = await Navigator.push<List<int>>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEmployeeScreen(),
                ),
              );
              if (selectedEmployees != null) {
                await _loadData();
                setState(() {
                  final currentSet = _selectedEmployeesForShift.toSet();
                  final newSet = selectedEmployees.toSet();
                  _selectedEmployeesForShift = currentSet
                      .union(newSet)
                      .toList();
                });
              }
            },
          ),
        ],
      ),
      body: _employees.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Your shift tracking will appear here.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const Text(
                    'Tap below to begin.',
                    style: TextStyle(fontSize: 18),
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
                      _showAddEmployeeDialog(); // 👈 Open the same dialog
                    },
                    child: const Text(
                      'Add Employee',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Week Navigation
                Container(
                  color: Colors.white,
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
                    availableCalendarFormats: const {
                      CalendarFormat.week: 'Week',
                    },
                    startingDayOfWeek: StartingDayOfWeek.monday,
                  ),
                // Shift Table
                Expanded(child: _buildShiftTable()),
              ],
            ),
      floatingActionButton: _employees.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              onPressed: () {
                _showAddEmployeeDialog(); // 👈 this opens the custom dialog directly
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildShiftTable() {
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateFormat = DateFormat('d');
    const double cellWidth = 75.0;
    const double rowHeight = 50.0;
    final double tableWidth = cellWidth * days.length;

    return Row(
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
                    right: BorderSide(color: Colors.grey.shade300, width: 1.0),
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
              // Employee Names
              Expanded(
                child: ListView.builder(
                  controller: _verticalController,
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final employee = _employees[index];
                    if (_selectedEmployeesForShift.isNotEmpty &&
                        !_selectedEmployeesForShift.contains(
                          employee.employeeId,
                        )) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onLongPress: () =>
                          _showDeleteEmployeeDialog(employee.employeeId!),
                      child: Container(
                        height: rowHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                            ), // Horizontal divider
                            right: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.0, // Vertical divider
                            ),
                          ),
                        ),
                        child: Text(
                          employee.name,
                          style: const TextStyle(fontSize: 14.0),
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
                                bottom: BorderSide(color: Colors.grey.shade300),
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
                    // Shift Cells
                    Expanded(
                      child: ListView.builder(
                        controller: _verticalController,
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final employee = _employees[index];
                          if (_selectedEmployeesForShift.isNotEmpty &&
                              !_selectedEmployeesForShift.contains(
                                employee.employeeId,
                              )) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            height: rowHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                ), // Horizontal divider
                              ),
                            ),
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
                                final startTimeMillis = shift['start_time'];
                                final endTimeMillis = shift['end_time'];

                                String formatTime(int? millis) {
                                  if (millis == null) return '';
                                  final dt =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        millis,
                                      );
                                  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                }

                                final startTime = formatTime(startTimeMillis);
                                final endTime = formatTime(endTimeMillis);

                                return Container(
                                  width: cellWidth,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1.0, // Vertical divider
                                      ),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _showShiftDialog(
                                        employee.employeeId!,
                                        day,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color:
                                            (shiftName != null &&
                                                shiftName.isNotEmpty)
                                            ? Colors.deepPurple[100]
                                            : null,
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                      ),
                                      child:
                                          (shiftName != null &&
                                              shiftName.isNotEmpty)
                                          ? Text(
                                              [
                                                shiftName,
                                                if (startTime.isNotEmpty &&
                                                    endTime.isNotEmpty)
                                                  '$startTime-$endTime',
                                              ].join('\n'),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 10.0,
                                              ),
                                            )
                                          : const Icon(Icons.add, size: 14.0),
                                    ),
                                  ),
                                );
                              }),
                            ),
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
    // Fetch all employees
    final rawAllEmployees = await _dbHelper.getEmployees();
    final allEmployees = rawAllEmployees
        .map((e) => Employee.fromMap(e))
        .toList();

    // Fetch current week employees
    final weekStart = _currentWeekStart.millisecondsSinceEpoch;
    final rawWeekEmployees = await _dbHelper.getEmployeesForWeek(weekStart);
    final currentWeekEmployees = rawWeekEmployees
        .map((e) => Employee.fromMap(e))
        .toList();

    final currentWeekEmployeeIds = currentWeekEmployees
        .map((e) => e.employeeId!)
        .toSet();

    final availableEmployees = allEmployees
        .where((e) => !currentWeekEmployeeIds.contains(e.employeeId))
        .toList();

    

    List<int> selectedEmployeeIds = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Select Employees'),
              content: Container(
                width: double.maxFinite,
                height: 400,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  itemCount: availableEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = availableEmployees[index];
                    final isSelected = selectedEmployeeIds.contains(
                      employee.employeeId,
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name ?? '',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID ${employee.employeeId?.toString().padLeft(4, '0') ?? ''}',
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
                                  selectedEmployeeIds.add(employee.employeeId!);
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
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 150));
                    if (mounted) {
                      await _addEmployeeDialog(context);
                    }
                  },
                  child: const Text(
                    'Add New',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    for (int empId in selectedEmployeeIds) {
                      await _dbHelper.addEmployeeToWeek(empId, weekStart);
                    }
                    await _loadData();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
