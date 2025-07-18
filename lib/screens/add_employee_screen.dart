import 'package:flutter/material.dart';
import 'package:shiftly/models/employee.dart';
import 'package:shiftly/db/database_helper.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Employee> _employees = [];

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

  Future<bool> _employeeIdExists(int id) async {
    final employees = await _dbHelper.getEmployees();
    return employees.any((e) => e['employee_id'] == id);
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
      return Dialog(
        insetPadding: const EdgeInsets.all(16), // Padding around the dialog
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // Increased width (80% of screen width)
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
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
                          Navigator.pop(context);
                          await _loadEmployees();
                        }
                      }
                    },
                    child: const Text(
                      'Add',
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
}



  Future<void> _updateEmployeeDialog(Employee employee) async {
  final TextEditingController nameController = TextEditingController(
    text: employee.name,
  );
  final TextEditingController idController = TextEditingController(
    text: employee.employeeId.toString(),
  );

  await showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        // backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16), // Provide a little padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width, // Full screen width
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Employee ID (Read-Only)
              TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Employee ID'),
              ),
              const SizedBox(height: 12),
              // Employee Name (Editable)
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Employee Name'),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey, // Text color (deep purple)
                        fontSize: 14, // Font size
                        fontWeight: FontWeight.bold, // Bold font
                      ),
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
                      final updatedName = nameController.text.trim();
                      if (updatedName.isNotEmpty) {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await _dbHelper.updateEmployee(
                            Employee(
                              employeeId: employee.employeeId,
                              name: updatedName,
                            ),
                          );

                          // Close both dialogs
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(); // Loading dialog
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(); // Update dialog

                          // Refresh the list
                          await _loadEmployees();
                        } catch (e) {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(); // Loading dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating employee: $e')),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Update', // Button text
                      style: TextStyle(
                        color: Colors.deepPurple, // Text color (deep purple)
                        fontSize: 18, // Font size set to 18
                        fontWeight: FontWeight.bold, // Bold font
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 40,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: Align(
          alignment: Alignment.centerLeft,
          child: const Text(
            'Add Employee',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final employee = _employees[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: InkWell(
              onTap: () => _updateEmployeeDialog(employee),
              child: Column(
                children: [
                  Container(
                    width: double.infinity, // Ensures full width
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                          '${employee.employeeId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            onPressed: _addEmployeeDialog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
