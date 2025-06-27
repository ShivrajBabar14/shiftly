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

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Add Employee',
            style: TextStyle(fontSize: 24), // Reduced text size
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Wider dialog
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
                    Navigator.pop(context);
                    await _loadEmployees();
                  }
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(fontSize: 20), 
              ),
            ),
          ],
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
        return AlertDialog(
          title: const Text('Update Employee', style: TextStyle(fontSize: 24)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  keyboardType: TextInputType.number,
                  readOnly:
                      true, // Make ID read-only since we shouldn't change it
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
              child: const Text('Update', style: TextStyle(fontSize: 20)),
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
                          'ID: ${employee.employeeId}',
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
