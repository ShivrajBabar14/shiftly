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
  final TextEditingController _nameController = TextEditingController();
  List<Employee> _employees = [];
  final List<int> _selectedEmployees = [];

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

  Future<void> _addEmployee(String name) async {
    if (name.isEmpty) return;
    await _dbHelper.insertEmployee(name);
    _nameController.clear();
    await _loadEmployees();
  }

  Future<void> _deleteEmployee(int id) async {
    await _dbHelper.deleteEmployee(id); // Ensure this method exists
    await _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.red[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addEmployee,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  onPressed: () => _addEmployee(_nameController.text),
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                return CheckboxListTile(
                  title: Text(employee.name),
                  subtitle: Text('ID: ${employee.employeeId}'),
                  value: _selectedEmployees.contains(employee.employeeId),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedEmployees.add(employee.employeeId!);
                      } else {
                        _selectedEmployees.remove(employee.employeeId);
                      }
                    });
                  },
                  secondary: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEmployee(employee.employeeId!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context, _selectedEmployees);
              },
              child: const Text(
                'Add Selected to Shift',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
