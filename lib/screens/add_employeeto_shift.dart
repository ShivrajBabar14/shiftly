import 'package:flutter/material.dart';
import 'package:shiftly/models/employee.dart';
import 'package:shiftly/db/database_helper.dart';

class SelectEmployeeForShiftScreen extends StatefulWidget {
  const SelectEmployeeForShiftScreen({super.key});

  @override
  State<SelectEmployeeForShiftScreen> createState() =>
      _SelectEmployeeForShiftScreenState();
}

class _SelectEmployeeForShiftScreenState
    extends State<SelectEmployeeForShiftScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Employee> _employees = [];
  Set<int> _selectedEmployeeIds = {};

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await _dbHelper.getEmployees();
    setState(() {
      _employees = employees.map((e) => Employee.fromMap(e)).toList();
    });
  }

  void _toggleSelection(int employeeId) {
    setState(() {
      if (_selectedEmployeeIds.contains(employeeId)) {
        _selectedEmployeeIds.remove(employeeId);
      } else {
        _selectedEmployeeIds.add(employeeId);
      }
    });
  }

  void _submitSelectedEmployees() async {
  final selectedEmployees = _employees
      .where((employee) => _selectedEmployeeIds.contains(employee.employeeId))
      .toList();

  // Example shift values — replace these with actual inputs as needed
  const String day = 'monday';
  final int weekStart =
      DateTime.now().millisecondsSinceEpoch; // Should be start of the week
  const String shiftName = 'Morning Shift';
  const int startTime =
      9 * 60 * 60 * 1000; // 9:00 AM in milliseconds from midnight
  const int endTime =
      17 * 60 * 60 * 1000; // 5:00 PM in milliseconds from midnight

  for (var employee in selectedEmployees) {
    final start = weekStart + startTime;
    final end = weekStart + endTime;

    await _dbHelper.insertOrUpdateShift(
      employeeId: employee.employeeId!,
      day: day,
      weekStart: weekStart,
      shiftName: shiftName,
      startTime: start,
      endTime: end,
    );
  }

  // Return the selected employee IDs
  Navigator.pop(context, _selectedEmployeeIds.toList());
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 40,
        title: const Text(
          'Select Employees',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final employee = _employees[index];
          final isSelected = _selectedEmployeeIds.contains(employee.employeeId);

          return GestureDetector(
            onTap: () => _toggleSelection(employee.employeeId!),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'ID: ${employee.employeeId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          activeColor: Colors.deepPurple,
                          onChanged: (value) {
                            _toggleSelection(employee.employeeId!);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _submitSelectedEmployees,
          child: const Text(
            'Add Employee to Shift',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
