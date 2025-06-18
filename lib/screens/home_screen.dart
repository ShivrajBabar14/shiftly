import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  // Sample data placeholders
  final DateTime _currentWeekStart = DateTime.now();
  final List<Employee> _employees = [
    Employee(employeeId: 1, name: 'Alice'),
    Employee(employeeId: 2, name: 'Bob'),
    Employee(employeeId: 3, name: 'Charlie'),
  ];

  final List<Map<String, dynamic>> _shiftTimings = [
    {
      'employee_id': 1,
      'day': 'Mon',
      'shift_name': 'Morning',
      'start_time': '9:00',
      'end_time': '17:00',
    },
    {
      'employee_id': 2,
      'day': 'Tue',
      'shift_name': 'Evening',
      'start_time': '13:00',
      'end_time': '21:00',
    },
    // Add more shift data as needed
  ];

  void _showShiftDialog(int employeeId, String day) {
    // Implement your dialog logic here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shift for Employee $employeeId on $day'),
        content: Text('Shift details here...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTable() {
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateFormat = DateFormat('d');

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Header Row
            SizedBox(
              height: 50.0,
              child: Row(
                children: [
                  // Fixed Employee Header
                  Container(
                    width: 120.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text(
                      'Employee',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Days Header (scrolls horizontally)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(days.length, (index) {
                          final dayDate = _currentWeekStart.add(Duration(days: index));
                          return Container(
                            width: 100.0,
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  days[index],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(dateFormat.format(dayDate)),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body with synchronized scrolling
            Expanded(
              child: Row(
                children: [
                  // Fixed Employee Column (scrolls vertically)
                  SizedBox(
                    width: 120.0,
                    child: Scrollbar(
                      controller: _verticalController,
                      child: ListView.builder(
                        controller: _verticalController,
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final employee = _employees[index];
                          return Container(
                            height: 60.0,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Text(employee.name),
                          );
                        },
                      ),
                    ),
                  ),
                  // Scrollable Days Table (scrolls both vertically and horizontally)
                  Expanded(
                    child: Scrollbar(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 100.0 * days.length,
                          child: ListView.builder(
                            controller: _verticalController,
                            itemCount: _employees.length,
                            itemBuilder: (context, employeeIndex) {
                              final employee = _employees[employeeIndex];
                              return SizedBox(
                                height: 60.0,
                                child: Row(
                                  children: List.generate(days.length, (dayIndex) {
                                    final day = days[dayIndex];
                                    final shift = _shiftTimings.firstWhere(
                                      (st) =>
                                          st['employee_id'] == employee.employeeId &&
                                          st['day'].toString().toLowerCase() ==
                                              day.toLowerCase(),
                                      orElse: () => {},
                                    );

                                    final shiftName = shift['shift_name']?.toString();
                                    final startTime = shift['start_time']?.toString();
                                    final endTime = shift['end_time']?.toString();

                                    return InkWell(
                                      onTap: () {
                                        _showShiftDialog(employee.employeeId!, day);
                                      },
                                      child: Container(
                                        width: 100.0,
                                        padding: const EdgeInsets.all(4.0),
                                        decoration: BoxDecoration(
                                          color: (shiftName != null && shiftName.isNotEmpty)
                                              ? Colors.red[100]
                                              : null,
                                          border: Border(
                                            bottom: BorderSide(color: Colors.grey.shade300),
                                            right: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          borderRadius: (shiftName != null && shiftName.isNotEmpty)
                                              ? BorderRadius.circular(4.0)
                                              : null,
                                        ),
                                        child: (shiftName != null && shiftName.isNotEmpty)
                                            ? Text(
                                                [
                                                  shiftName,
                                                  if (startTime != null && endTime != null)
                                                    '$startTime-$endTime',
                                                ].join('\n'),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12.0,
                                                ),
                                              )
                                            : const Icon(Icons.add, size: 16.0),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Shift Tracker'),
      ),
      body: _buildShiftTable(),
    );
  }
}

class Employee {
  final int? employeeId;
  final String name;

  Employee({this.employeeId, required this.name});
}
