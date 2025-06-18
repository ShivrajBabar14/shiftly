class Employee {
  final int? employeeId;
  final String name;

  Employee({this.employeeId, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'name': name,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      employeeId: map['employee_id'],
      name: map['name'],
    );
  }
}