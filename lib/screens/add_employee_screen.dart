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
            style: TextStyle(fontSize: 18), // Reduced text size
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
                style: TextStyle(fontSize: 18), // Bigger Add button text
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteEmployeeDialog(int employeeId) async {
    final employee = _employees.firstWhere((e) => e.employeeId == employeeId);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete ${employee.name}?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // just close dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                await _dbHelper.deleteEmployee(employeeId);
                await _dbHelper.deleteShiftsForEmployee(employeeId);
                Navigator.of(context).pop(); // close dialog first
                await _loadEmployees(); // refresh list
              },
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
          title: const Text(
            'Update Employee',
            style: TextStyle(fontSize: 18), // Reduced title size
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
                final updatedName = nameController.text.trim();
                if (updatedName.isNotEmpty) {
                  await _dbHelper.updateEmployee(
                    Employee(
                      employeeId: employee.employeeId,
                      name: updatedName,
                    ),
                  );
                  Navigator.pop(context);
                  await _loadEmployees();
                }
              },
              child: const Text(
                'Update',
                style: TextStyle(fontSize: 18), // Bigger Update button text
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
        titleSpacing: 0, // Aligns title right next to back arrow
        leadingWidth: 40,
        title: const Text(
          'Add Employee',
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
          return GestureDetector(
            onTap: () => _updateEmployeeDialog(employee),
            onLongPress: () => _showDeleteEmployeeDialog(employee.employeeId!),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
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
