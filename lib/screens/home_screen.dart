import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Shiftwise/db/database_helper.dart';
import 'package:Shiftwise/models/employee.dart';
import 'subscription.dart';
import 'package:Shiftwise/widgets/limits_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sidbar.dart';
import 'employee_shift_screen.dart'; // Add import for new screen
import 'package:Shiftwise/services/subscription_service.dart';
import 'package:Shiftwise/services/backup_refresh_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter/material.dart';

final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: homeScreenKey);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
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

  // Add isFreeUser flag to indicate free user status
  bool isFreeUser = true;
  bool _subscriptionStatusLoaded = false;

  // New flag to control overlay visibility
  bool _showProOverlay = false;

  bool get isLoadingSubscription => !_subscriptionStatusLoaded;

  Timer? _subscriptionRefreshTimer;

  DateTime get _actualCurrentWeekStart {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return monday;
  }

  DateTime get _actualCurrentWeekEnd {
    final start = _actualCurrentWeekStart;
    final sunday = DateTime(
      start.year,
      start.month,
      start.day,
    ).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return sunday;
  }

  bool _isOutsideActualCurrentWeek(DateTime date) {
    return date.isBefore(_actualCurrentWeekStart) ||
        date.isAfter(_actualCurrentWeekEnd);
  }

  Timer? _autoBackupTimer;
  // Removed duplicate _subscriptionRefreshTimer declaration

  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Calendar-related initializations
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 365));
    _lastDay = DateTime.now().add(const Duration(days: 365));

    // Initialize week range first
    _calculateWeekRange(_selectedDay);

    // Load initial subscription status and data
    _loadSubscriptionStatus();

    // Immediately refresh subscription status to update UI on app start
    _refreshSubscriptionStatus();

    // Start periodic subscription status refresh every 5 minutes
    _subscriptionRefreshTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) {
      SubscriptionService().refreshSubscriptionStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('DEBUG: didChangeDependencies called');
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
      print('DEBUG: Subscribed to routeObserver');
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _autoBackupTimer?.cancel();
    _subscriptionRefreshTimer?.cancel();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    print('DEBUG: didPopNext called');
    // Called when the current route is shown again after popping a next route.
    _refreshSubscriptionStatus();
  }

  void _fullRefreshHome() async {
    await _loadData();
    setState(() {}); // Refresh UI
  }

  Future<void> _loadShifts() async {
    final weekStart = _currentWeekStart.millisecondsSinceEpoch;
    final shifts = await _dbHelper.getEmployeesWithShiftsForWeek(weekStart);
    setState(() {
      _shiftTimings = shifts;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh subscription status when app resumes
      _refreshSubscriptionStatus();
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    print('DEBUG: Starting to load subscription status...');
    await SubscriptionService().loadSubscriptionStatus();
    final subscribed = SubscriptionService().isSubscribed;
    print('DEBUG: Subscription status loaded: $subscribed');
    print('DEBUG: isFreeUser set to: ${!subscribed}');
    print('DEBUG: _subscriptionStatusLoaded set to: true');
    setState(() {
      isFreeUser = !subscribed;
      _subscriptionStatusLoaded = true;
    });

    // Manage auto-backup timer based on subscription status
    if (!isFreeUser) {
      _autoBackupTimer ??= Timer.periodic(const Duration(hours: 8), (
        timer,
      ) async {
        await DatabaseHelper().backupDatabase();
      });
    } else {
      _autoBackupTimer?.cancel();
      _autoBackupTimer = null;
    }

    // Then load data
    _initWeekStartAndLoadData();
    _loadEmployees();

    // Check and update overlay visibility after loading subscription and employees
    _checkProOverlayVisibility();
  }

  // Add this method to refresh subscription status when returning from subscription screen
  Future<void> _refreshSubscriptionStatus() async {
    await SubscriptionService().refreshSubscriptionStatus();
    final subscribed = SubscriptionService().isSubscribed;
    print('DEBUG: Subscription status refreshed: $subscribed');
    if (!mounted) return;
    setState(() {
      isFreeUser = !subscribed;
    });

    // Update UI based on new subscription status
    _checkProOverlayVisibility();
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

  // Future<void> _loadEmployeesForWeek(int weekId) async {
  //   final employeeMaps = await dbHelper.getEmployeesForWeek(weekId);

  //   final employees = employeeMaps.map((map) => Employee.fromMap(map)).toList();

  //   setState(() {
  //     _employees = employees;
  //   });
  // }

  Future<void> _addEmployeeDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();

    // Check employee count and limit for free users
    final employees = await _dbHelper.getEmployees();
    if (isFreeUser && employees.length >= 5) {
      // Changed from widget.isFreeUser to isFreeUser
      await showDialog(
        context: context,
        builder: (context) {
          return LimitsDialog(
            onGoPro: () {
              Navigator.of(context).pop();
              // Navigate to pro screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShiftlyProScreen()),
              );
            },
            onContinueFree: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
      return;
    }

    // Find the highest current ID
    int nextId = 1; // Default start
    if (employees.isNotEmpty) {
      final ids = employees.map((e) => e['employee_id'] as int).toList();
      nextId = (ids.reduce((a, b) => a > b ? a : b)) + 1;
    }

    idController.text = nextId.toString(); // Set default value

    // Get existing names for duplicate checking (case insensitive)
    final existingNames = employees
        .map((e) => e['name'].toString().toLowerCase().trim())
        .toSet();

    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Employee ID (Editable)
                TextField(
                  controller: idController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    labelStyle: TextStyle(color: Color(0xFF9E9E9E)),
                  ),
                ),
                const SizedBox(height: 10),
                // Employee Name (Editable with Capitalization)
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                    labelStyle: TextStyle(color: Color(0xFF9E9E9E)),
                  ),
                  textCapitalization: TextCapitalization.sentences,
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
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        final id = int.tryParse(idController.text);
                        final name = nameController.text.trim();

                        if (id != null && name.isNotEmpty) {
                          // Check for duplicate ID
                          final idExists = await _employeeIdExists(id);
                          if (idExists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Employee ID already exists'),
                                backgroundColor: Colors.deepPurple,
                              ),
                            );
                            return;
                          }

                          // Check for duplicate name (case insensitive)
                          if (existingNames.contains(name.toLowerCase())) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Employee name already exists'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          await _dbHelper.insertEmployeeWithId(id, name);
                          // Add employee to current week
                          final weekStart =
                              _currentWeekStart.millisecondsSinceEpoch;
                          await _dbHelper.addEmployeeToWeek(id, weekStart);
                          Navigator.pop(context);
                          await _loadEmployees();
                          await _loadData();
                          // Update shift table to include new employee
                          setState(() {
                            // Remove adding new employee id to _selectedEmployeesForShift to avoid hiding other employees
                            // final currentSet = _selectedEmployeesForShift
                            //     .toSet();
                            // currentSet.add(id);
                            // _selectedEmployeesForShift = currentSet.toList();
                            _selectedEmployeesForShift = [];
                          });
                        }
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
  }

  Future<bool> _employeeIdExists(int id) async {
    final employees = await _dbHelper.getEmployees();
    return employees.any((e) => e['employee_id'] == id);
  }

  Future<void> _loadData() async {
    try {
      if (_currentWeekStart == null) {
        print('Warning: _currentWeekStart is null in _loadData');
        return;
      }

      final weekStart = _currentWeekStart.millisecondsSinceEpoch;

      // Get employees specifically assigned to this week
      final weekEmployees = await _dbHelper.getEmployeesForWeek(weekStart);
      final weekData = await _dbHelper.getEmployeesWithShiftsForWeek(weekStart);

      // Keep existing employees and just update their shifts
      final shiftTimings = <Map<String, dynamic>>[];

      for (final row in weekData) {
        if (row['day'] != null) {
          shiftTimings.add({
            'employee_id': row['employee_id'],
            'day': row['day'],
            'week_start': weekStart,
            'shift_name': row['shift_name'],
            'start_time': row['start_time'],
            'end_time': row['end_time'],
          });
        }
      }

      setState(() {
        _shiftTimings = shiftTimings;
        _isLoading = false;

        // Only include employees that are actually assigned to this week
        final employeeMap = <int, Employee>{};
        for (final employee in weekEmployees) {
          final id = employee['employee_id'] as int;
          if (!employeeMap.containsKey(id)) {
            employeeMap[id] = Employee(
              employeeId: id,
              name: employee['name'] as String,
            );
          }
        }
        _employees = employeeMap.values.toList();

        // Clear selection to prevent showing removed employees
        _selectedEmployeesForShift = _selectedEmployeesForShift
            .where((id) => employeeMap.containsKey(id))
            .toList();
      });

      _checkProOverlayVisibility();
    } catch (e, st) {
      print('Error in _loadData: $e\n$st');
      setState(() => _isLoading = false);
    }
  }

  /// Force refresh current week data without changing week
  Future<void> forceRefreshCurrentWeek() async {
    try {
      setState(() => _isLoading = true);

      // Reload data for current week
      await _loadData();

      // Also reload employees to ensure consistency
      await _loadEmployees();

      print('✅ Current week data refreshed automatically');
    } catch (e) {
      print('❌ Error refreshing current week: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      // Get employees from the most recent week (could be previous or next)
      final prevWeekStart = _currentWeekStart
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      final nextWeekStart = _currentWeekStart
          .add(const Duration(days: 7))
          .millisecondsSinceEpoch;

      // Try to get employees from previous week first
      var sourceWeekEmployees = await _dbHelper.getEmployeesForWeek(
        prevWeekStart,
      );

      // If previous week has no employees, try next week
      if (sourceWeekEmployees.isEmpty) {
        sourceWeekEmployees = await _dbHelper.getEmployeesForWeek(
          nextWeekStart,
        );
      }

      // If we found employees in either week, copy them to current week
      if (sourceWeekEmployees.isNotEmpty) {
        for (final employee in sourceWeekEmployees) {
          await _dbHelper.addEmployeeToWeek(
            employee['employee_id'] as int,
            weekStart,
          );
        }
      }
    }
  }

  Future<void> _onWeekChanged(DateTime startOfWeek) async {
    final newWeekStart = startOfWeek.subtract(
      Duration(days: startOfWeek.weekday - 1),
    );

    if (newWeekStart == _currentWeekStart) {
      return;
    }

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

    final weekStartDate = _dbHelper.getStartOfWeek(_currentWeekStart);
    final weekStart = weekStartDate.millisecondsSinceEpoch;

    final shouldRefresh = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(
                  child: Text(
                    'Remove Employee',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to remove ${employee.name} from this week\'s shift table?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '(Employee will remain in your main employee list)',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false); // No refresh
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final deletedCount = await _dbHelper
                            .removeEmployeeFromWeek(employeeId, weekStart);

                        final db = await _dbHelper.database;
                        final deletedShifts = await db.delete(
                          'shift_timings',
                          where: 'employee_id = ? AND week_start = ?',
                          whereArgs: [employeeId, weekStart],
                        );

                        print(
                          "🗑️ Removed employee $employeeId from week $weekStart: $deletedCount assignments, $deletedShifts shifts",
                        );

                        Navigator.of(dialogContext).pop(true); // <-- Important
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.deepPurple,
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

    if (shouldRefresh == true) {
      await _loadEmployees();
      await _loadData();
      setState(() {}); // Trigger UI rebuild with latest DB state
    }
  }

  void _showShiftDialog(int employeeId, String day) async {
    final selectedDate = _currentWeekStart.add(
      Duration(
        days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(day),
      ),
    );

    if (isLoadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading subscription status, please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (isFreeUser && _isOutsideActualCurrentWeek(selectedDate)) {
      await showDialog(
        context: context,
        builder: (context) {
          return LimitsDialog(
            onGoPro: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShiftlyProScreen()),
              );
            },
            onContinueFree: () => Navigator.of(context).pop(),
          );
        },
      );
      return;
    }

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

    final textEditingController = TextEditingController(text: shiftName);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        '${employee.name} – ${day.toUpperCase()} (${selectedDate.day})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Shift name', style: TextStyle(fontSize: 16)),
                    RawAutocomplete<String>(
                      textEditingController: textEditingController,
                      focusNode: FocusNode(),
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        final input = textEditingValue.text.toLowerCase();
                        final allShiftSuggestions = await _dbHelper
                            .getAllShiftSuggestions();

                        final suggestionSet = <String>{};

                        String format(int? millis) {
                          if (millis == null) return '';
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            millis,
                          );
                          return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                        }

                        for (var st in allShiftSuggestions) {
                          final rawName =
                              (st['shift_name'] as String?)?.trim() ?? '';
                          if (rawName.isEmpty) continue;

                          final s = format(st['start_time'] as int?);
                          final e = format(st['end_time'] as int?);

                          if (s.isNotEmpty && e.isNotEmpty) {
                            // Shift has time → only show time version
                            suggestionSet.add('$rawName ($s-$e)');
                          } else {
                            // Shift has no time → show plain version
                            suggestionSet.add(rawName);
                          }
                        }

                        final suggestionList = suggestionSet.toList();

                        if (input.isEmpty) {
                          return suggestionList;
                        } else {
                          return suggestionList.where(
                            (opt) => opt.toLowerCase().contains(input),
                          );
                        }
                      },

                      onSelected: (String selection) {
                        final regex = RegExp(
                          r'^(.*?)\s*\((\d{2}):(\d{2})-(\d{2}):(\d{2})\)?$',
                        );
                        final match = regex.firstMatch(selection);
                        final cleanName = match?.group(1)?.trim() ?? selection;

                        textEditingController.text = cleanName;
                        textEditingController.selection =
                            TextSelection.collapsed(offset: cleanName.length);

                        if (match != null) {
                          final sHour = int.tryParse(match.group(2) ?? '');
                          final sMin = int.tryParse(match.group(3) ?? '');
                          final eHour = int.tryParse(match.group(4) ?? '');
                          final eMin = int.tryParse(match.group(5) ?? '');

                          setState(() {
                            if (sHour != null && sMin != null) {
                              startTime = TimeOfDay(hour: sHour, minute: sMin);
                            }
                            if (eHour != null && eMin != null) {
                              endTime = TimeOfDay(hour: eHour, minute: eMin);
                            }
                          });
                        }
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            // Link external controller (textEditingController) to internal one (controller)
                            controller.text = textEditingController.text;
                            controller.selection =
                                textEditingController.selection;

                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                border: UnderlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (value) {
                                textEditingController.text = value;
                                textEditingController.selection =
                                    controller.selection;

                                String cap = value
                                    .split(' ')
                                    .map(
                                      (word) => word.isEmpty
                                          ? word
                                          : '${word[0].toUpperCase()}${word.substring(1)}',
                                    )
                                    .join(' ');
                                if (cap != value) {
                                  controller.value = TextEditingValue(
                                    text: cap,
                                    selection: TextSelection.collapsed(
                                      offset: cap.length,
                                    ),
                                  );
                                  textEditingController.text = cap;
                                  textEditingController.selection =
                                      controller.selection;
                                }
                              },
                            );
                          },

                      optionsViewBuilder: (context, onSelected, options) {
                        return Material(
                          elevation: 4,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              children: options.map((option) {
                                return ListTile(
                                  title: Text(option),
                                  onTap: () => onSelected(option),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time'),
                              const SizedBox(height: 8),
                              InkWell(
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
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        startTime != null
                                            ? startTime!.format(context)
                                            : '',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time'),
                              const SizedBox(height: 8),
                              InkWell(
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
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        endTime != null
                                            ? endTime!.format(context)
                                            : '',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () async {
                            shiftName = textEditingController.text.trim();
                            final hasName =
                                shiftName != null && shiftName!.isNotEmpty;
                            final hasTime =
                                startTime != null && endTime != null;

                            if (hasName || hasTime) {
                              int? startTimeMillis;
                              int? endTimeMillis;

                              if (hasTime) {
                                final startDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  startTime!.hour,
                                  startTime!.minute,
                                );
                                startTimeMillis =
                                    startDateTime.millisecondsSinceEpoch;

                                final endDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  endTime!.hour,
                                  endTime!.minute,
                                );
                                endTimeMillis =
                                    endDateTime.millisecondsSinceEpoch;
                              }

                              await _dbHelper.insertOrUpdateShift(
                                employeeId: employeeId,
                                day: day.toLowerCase(),
                                weekStart: weekStart,
                                shiftName: hasName ? shiftName : null,
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
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAddEmployeePressed() async {
    if (isLoadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading subscription status, please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('DEBUG: isFreeUser in _handleAddEmployeePressed: $isFreeUser');

    if (!isFreeUser) {
      await _showAddEmployeeDialog();
      return;
    }

    final weekStart = _currentWeekStart.millisecondsSinceEpoch;
    final rawWeekEmployees = await _dbHelper.getEmployeesForWeek(weekStart);
    final currentWeekEmployees = rawWeekEmployees
        .map((e) => Employee.fromMap(e))
        .toList();

    if (currentWeekEmployees.length >= 5) {
      await showDialog(
        context: context,
        builder: (context) {
          return LimitsDialog(
            onGoPro: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShiftlyProScreen()),
              );
            },
            onContinueFree: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
      return;
    }
    await _showAddEmployeeDialog();
  }

  // New method to check if user is free for previous and next week and update overlay visibility
  Future<void> _checkProOverlayVisibility() async {
    if (!isFreeUser) {
      setState(() {
        _showProOverlay = false;
      });
      return;
    }

    final prevWeekStart = _currentWeekStart
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final nextWeekStart = _currentWeekStart
        .add(const Duration(days: 7))
        .millisecondsSinceEpoch;

    final prevWeekShifts = await _dbHelper.getEmployeesWithShiftsForWeek(
      prevWeekStart,
    );
    final nextWeekShifts = await _dbHelper.getEmployeesWithShiftsForWeek(
      nextWeekStart,
    );

    final bool isFreePrevWeek = prevWeekShifts.isEmpty;
    final bool isFreeNextWeek = nextWeekShifts.isEmpty;

    setState(() {
      _showProOverlay = isFreePrevWeek && isFreeNextWeek;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Week check logic
    bool isCurrentWeek() {
      final now = DateTime.now();
      final nowWeekStart = now.subtract(Duration(days: now.weekday - 1));
      return _currentWeekStart.year == nowWeekStart.year &&
          _currentWeekStart.month == nowWeekStart.month &&
          _currentWeekStart.day == nowWeekStart.day;
    }

    final bool showOverlay = isFreeUser && !isCurrentWeek();

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(onBackupRestore: _fullRefreshHome),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'Shiftwise',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (!isFreeUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/crown.svg',
                  width: 15,
                  height: 15,
                  color: Color.fromARGB(255, 255, 183, 0),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isFreeUser)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: () async {
                  final subscriptionSuccess = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => ShiftlyProScreen()),
                  );
                  if (subscriptionSuccess == true) {
                    await _loadSubscriptionStatus();
                    await _loadData();
                    setState(() {
                      _showProOverlay = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  textStyle: const TextStyle(fontSize: 16),
                  minimumSize: const Size(80, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Go Pro'),
              ),
            ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Week Navigation
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 30),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () {
                    _onWeekChanged(
                      _currentWeekStart.subtract(const Duration(days: 7)),
                    );
                  },
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 30),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () {
                    _onWeekChanged(
                      _currentWeekStart.add(const Duration(days: 7)),
                    );
                  },
                ),
              ],
            ),
          ),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_employees.isEmpty
                      ? Stack(
                          children: [
                            _buildEmptyShiftTable(),
                            if (!_currentWeekStart.isBefore(
                                  _actualCurrentWeekStart,
                                ) &&
                                !showOverlay)
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
                                        _handleAddEmployeePressed();
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
                      : Container(
                          decoration: const BoxDecoration(),
                          child: _buildShiftTable(),
                        )),
          ),
        ],
      ),
      floatingActionButton: showOverlay
          ? null
          : (_employees.isEmpty &&
                !_currentWeekStart.isBefore(_actualCurrentWeekStart))
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              onPressed: _handleAddEmployeePressed,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildEmptyShiftTable() {
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateFormat = DateFormat('d');
    const double cellWidth = 75.0;
    const double rowHeight = 40.0;
    final double tableWidth = cellWidth * days.length;

    // Week check logic
    bool isCurrentWeek() {
      final now = DateTime.now();
      final nowWeekStart = now.subtract(Duration(days: now.weekday - 1));
      return _currentWeekStart.year == nowWeekStart.year &&
          _currentWeekStart.month == nowWeekStart.month &&
          _currentWeekStart.day == nowWeekStart.day;
    }

    final bool showOverlay = isFreeUser && !isCurrentWeek();

    return Stack(
      children: [
        Opacity(
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
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
                    // Empty Employee Names
                    Expanded(child: Container()),
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          // Empty Shift Cells
                          Expanded(
                            child: Container(decoration: const BoxDecoration()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showOverlay)
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.9)),
          ),
        if (showOverlay)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Unlock Advanced Shift Scheduling",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "You can create shifts for the upcoming or previous weeks with the Pro version.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.5, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ShiftlyProScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Go Pro",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShiftTable() {
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateFormat = DateFormat('d');
    const double cellWidth = 75.0;
    const double rowHeight = 70.0;
    final today = DateTime.now();

    final todayIndex = today.difference(_currentWeekStart).inDays;

    final visibleEmployees = _selectedEmployeesForShift.isEmpty
        ? _employees
        : _employees
              .where((e) => _selectedEmployeesForShift.contains(e.employeeId))
              .toList();

    bool isCurrentWeek() {
      final now = DateTime.now();
      final nowWeekStart = now.subtract(Duration(days: now.weekday - 1));
      return _currentWeekStart.year == nowWeekStart.year &&
          _currentWeekStart.month == nowWeekStart.month &&
          _currentWeekStart.day == nowWeekStart.day;
    }

    final bool showOverlay = isFreeUser && !isCurrentWeek();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Scrollbar(
              thumbVisibility: true,
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _verticalController,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky Employee Column
                    Column(
                      children: [
                        Container(
                          height: rowHeight,
                          width: 100.0,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                              right: BorderSide(
                                color: Colors.grey.shade400,
                                width: 0.3,
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
                        Column(
                          children: List.generate(visibleEmployees.length, (
                            index,
                          ) {
                            final employee = visibleEmployees[index];
                            return GestureDetector(
                              onLongPress: () => _showDeleteEmployeeDialog(
                                employee.employeeId!,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmployeeShiftScreen(
                                    employee: employee,
                                    weekStart: _currentWeekStart,
                                  ),
                                ),
                              ),
                              child: Container(
                                height: rowHeight,
                                width: 100.0,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? Colors.white
                                      : Colors.grey.shade100,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    right: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  employee.name
                                      .split(' ')
                                      .map(
                                        (word) => word.isNotEmpty
                                            ? word[0].toUpperCase() +
                                                  word.substring(1)
                                            : word,
                                      )
                                      .join(' '),
                                  style: const TextStyle(fontSize: 14.0),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    // Scrollable Shift Table
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _horizontalController,
                        child: SizedBox(
                          width: cellWidth * days.length,
                          child: Column(
                            children: [
                              // Days Header
                              Container(
                                height: rowHeight,
                                child: Table(
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  border: TableBorder(
                                    horizontalInside: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    verticalInside: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 0,
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
                                        index,
                                      ) {
                                        final dayDate = _currentWeekStart.add(
                                          Duration(days: index),
                                        );
                                        final isToday = DateUtils.isSameDay(
                                          dayDate,
                                          today,
                                        );
                                        return Container(
                                          height: rowHeight,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple,
                                            border: Border(
                                              top: isToday
                                                  ? BorderSide(
                                                      color: Color(0xFF03DAC5),
                                                      width: 1.0,
                                                    )
                                                  : BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                      width: 0,
                                                    ),
                                              left: isToday
                                                  ? BorderSide(
                                                      color: Color(0xFF03DAC5),
                                                      width: 1.0,
                                                    )
                                                  : BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                      width: 0,
                                                    ),
                                              right: BorderSide(
                                                color: isToday
                                                    ? Color(0xFF03DAC5)
                                                    : Colors.grey.shade300,
                                                width: 1.0,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                              ),
                              // Shift Rows
                              Column(
                                children: List.generate(visibleEmployees.length, (
                                  index,
                                ) {
                                  final employee = visibleEmployees[index];
                                  return Table(
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    border: TableBorder(
                                      horizontalInside: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                      verticalInside: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0,
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
                                              shift['shift_name']?.toString() ??
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

                                          final hasName = shiftName.isNotEmpty;
                                          final hasTime =
                                              startTime.isNotEmpty &&
                                              endTime.isNotEmpty;

                                          return InkWell(
                                            onTap: () => _showShiftDialog(
                                              employee.employeeId!,
                                              day,
                                            ),
                                            child: Container(
                                              height: rowHeight,
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.all(
                                                1.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: index.isEven
                                                    ? Colors.white
                                                    : Colors.grey.shade100,
                                                border: Border(
                                                  left: dayIndex == todayIndex
                                                      ? BorderSide(
                                                          color: Color(
                                                            0xFF03DAC5,
                                                          ),
                                                          width: 1.0,
                                                        )
                                                      : BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                          width: 0,
                                                        ),
                                                  right: dayIndex == todayIndex
                                                      ? BorderSide(
                                                          color: Color(
                                                            0xFF03DAC5,
                                                          ),
                                                          width: 1.0,
                                                        )
                                                      : BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                          width: 0,
                                                        ),
                                                  bottom:
                                                      dayIndex == todayIndex &&
                                                          index ==
                                                              visibleEmployees
                                                                      .length -
                                                                  1
                                                      ? BorderSide(
                                                          color: Color(
                                                            0xFF03DAC5,
                                                          ),
                                                          width: 2.0,
                                                        )
                                                      : BorderSide(
                                                          color: Colors
                                                              .transparent,
                                                        ),
                                                ),
                                              ),
                                              child: (hasName || hasTime)
                                                  ? Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4.0,
                                                            horizontal: 6.0,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4.0,
                                                            ),
                                                      ),
                                                      child: hasName && hasTime
                                                          ? RichText(
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              text: TextSpan(
                                                                children: [
                                                                  TextSpan(
                                                                    text:
                                                                        shiftName,
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          12.5,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        '\n($startTime-$endTime)',
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontSize:
                                                                          12.5,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : Text(
                                                              hasName
                                                                  ? shiftName
                                                                  : '$startTime-$endTime',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12.5,
                                                                color: Colors
                                                                    .black,
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
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showOverlay)
              Positioned.fill(
                child: Container(color: Colors.white.withOpacity(0.9)),
              ),
            if (showOverlay)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 80,
                  ), // Adjust top spacing as needed
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Unlock Advanced Shift Scheduling",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "You can create shifts for the upcoming weeks in advance with Pro version",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.5, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShiftlyProScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Go Pro",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddEmployeeDialog() async {
    final weekStart = _currentWeekStart.millisecondsSinceEpoch;
    final rawWeekEmployees = await _dbHelper.getEmployeesForWeek(weekStart);
    final currentWeekEmployees = rawWeekEmployees
        .map((e) => Employee.fromMap(e))
        .toList();

    // Check if subscription status is loaded
    if (isLoadingSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading subscription status, please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check free user limit for max 5 employees
    if (isFreeUser && currentWeekEmployees.length >= 5) {
      await showDialog(
        context: context,
        builder: (context) {
          return LimitsDialog(
            onGoPro: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShiftlyProScreen()),
              );
            },
            onContinueFree: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
      return;
    }

    final rawAllEmployees = await _dbHelper.getEmployees();
    print('DEBUG: All employees raw data: \$rawAllEmployees');
    final allEmployees = rawAllEmployees
        .map((e) => Employee.fromMap(e))
        .toList();
    print('DEBUG: All employees parsed: \$allEmployees');

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
              insetPadding: const EdgeInsets.all(16),
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
                        TextButton(
                          style: TextButton.styleFrom(
                            // primary: Colors.deepPurple[700], // Text color (Deep Purple)
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ), // Padding
                            textStyle: const TextStyle(
                              fontSize: 18, // Font size set to 18
                              fontWeight: FontWeight
                                  .bold, // Optional: Add bold text for emphasis
                            ),
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
                              color: Colors.deepPurple,
                              fontSize: 18,
                            ), // Text color (deep purple)
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
