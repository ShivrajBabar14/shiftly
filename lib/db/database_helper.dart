import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shiftly/models/employee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _databaseVersion = 4;

  DateTime getStartOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Backup database file to public external storage backups folder
  Future<bool> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, 'shiftly.db'));

      // Get public documents directory
      final directories = await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (directories == null || directories.isEmpty) {
        print('❌ Could not access public documents directory');
        return false;
      }
      final directory = directories.first;

      final publicBackupDir = Directory(join(directory.path, 'ShiftlyBackups'));
      if (!await publicBackupDir.exists()) {
        await publicBackupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = File(join(publicBackupDir.path, 'shiftly_backup_$timestamp.db'));

      await dbFile.copy(backupFile.path);
      print('✅ Database backed up to ${backupFile.path}');
      return true;
    } catch (e) {
      print('❌ Error during database backup: $e');
      return false;
    }
  }

  // Restore latest backup from backups folder
  Future<bool> restoreLatestBackup() async {
    try {
      final directories = await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (directories == null || directories.isEmpty) {
        print('❌ Could not access public documents directory');
        return false;
      }
      final directory = directories.first;

      final backupDir = Directory(join(directory.path, 'ShiftlyBackups'));

      if (!await backupDir.exists()) {
        print('❌ Backup directory does not exist.');
        return false;
      }

      final backups = backupDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.db'))
          .toList();

      if (backups.isEmpty) {
        print('❌ No backup files found.');
        return false;
      }

      backups.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latestBackup = backups.first;

      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, 'shiftly.db'));

      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      await latestBackup.copy(dbFile.path);
      print('✅ Database restored from ${latestBackup.path}');
      return true;
    } catch (e) {
      print('❌ Error during database restore: $e');
      return false;
    }
  }

  Future<int> getCurrentWeekId() async {
    final db = await database;

    // Get start and end of current week as DateTime
    final DateTime startOfWeek = getStartOfWeek(DateTime.now());
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    final int startOfWeekMillis = startOfWeek.millisecondsSinceEpoch;
    final int endOfWeekMillis = endOfWeek.millisecondsSinceEpoch;

    // Query the week_info table using integer timestamps
    final List<Map<String, dynamic>> result = await db.query(
      'week_info',
      where: 'start_date = ? AND end_date = ?',
      whereArgs: [startOfWeekMillis, endOfWeekMillis],
    );

    int weekStart;
    if (result.isNotEmpty) {
      weekStart = result.first['start_date'] as int;
    } else {
      await db.insert('week_info', {
        'start_date': startOfWeekMillis,
        'end_date': endOfWeekMillis,
      });
      weekStart = startOfWeekMillis;
    }

    // Save the current weekStart to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_week_id', weekStart);

    return weekStart;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'shiftly.db');

    print('🔍 Database path: $path');
    final file = File(path);
    final exists = await file.exists();
    print('🔍 Database file exists: $exists');

    if (!exists) {
      print('🆕 Database does not exist, creating new database.');
    } else {
      print('✅ Database exists, opening existing database.');
    }

    // ❗ Uncomment the next line during development to reset DB if issues occur
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  // Get employees for current week
  // Get employees for current week
  Future<List<Map<String, dynamic>>> getEmployeesForWeek(int weekStart) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
    SELECT employees.* 
    FROM week_assignments
    INNER JOIN employees 
    ON week_assignments.employee_id = employees.employee_id
    WHERE week_assignments.week_start = ?
  ''',
      [weekStart],
    );
    return results;
  }

  Future<void> addEmployeeToWeek(int employeeId, int weekStart) async {
    final db = await database;

    // First add to week_assignments
    await db.insert('week_assignments', {
      'employee_id': employeeId,
      'week_start': weekStart,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Then create empty shift records
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    for (final day in days) {
      await db.insert('shift_timings', {
        'employee_id': employeeId,
        'week_start': weekStart,
        'day': day,
        'shift_name': null,
        'start_time': null,
        'end_time': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('✅ Added employee $employeeId to week $weekStart');
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implement proper migration strategy to preserve data
    if (oldVersion < 2 && newVersion >= 2) {
      await _migrateToVersion2(db);
    }
    if (oldVersion < 3 && newVersion >= 3) {
      await _migrateToVersion3(db);
    }
    // Add further migrations here as needed
  }

  Future<void> _migrateToVersion3(Database db) async {
    // Create the week_assignments table if it doesn't exist
    await db.execute('''
    CREATE TABLE IF NOT EXISTS week_assignments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      employee_id INTEGER NOT NULL,
      week_start INTEGER NOT NULL,
      FOREIGN KEY (employee_id) REFERENCES employees (employee_id),
      UNIQUE (employee_id, week_start)
    )
  ''');
  }

  // Insert employee with custom ID
  Future<int> insertEmployeeWithId(int id, String name) async {
    final db = await database;
    return await db.insert(
      'employees',
      {'employee_id': id, 'name': name},
      conflictAlgorithm: ConflictAlgorithm.replace, // in case ID already exists
    );
  }

  // Update employee name (ID is fixed)
  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update(
      'employees',
      {'name': employee.name},
      where: 'employee_id = ?',
      whereArgs: [employee.employeeId],
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE employees (
        employee_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shift_timings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        day TEXT NOT NULL,
        week_start INTEGER NOT NULL,
        shift_name TEXT,
        start_time INTEGER,
        end_time INTEGER,
        FOREIGN KEY (employee_id) REFERENCES employees (employee_id) ON DELETE CASCADE,
        UNIQUE(employee_id, day, week_start) ON CONFLICT REPLACE
      )
    ''');

    await db.execute('''
      CREATE TABLE week_info (
        week_id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        table_name TEXT
      )
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS week_assignments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    week_start INTEGER NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees (employee_id),
    UNIQUE (employee_id, week_start)
  )
''');
  }

  Future<int> removeEmployeeFromWeek(int employeeId, int weekStart) async {
    final db = await database;
    return await db.delete(
      'week_assignments',
      where: 'employee_id = ? AND week_start = ?',
      whereArgs: [employeeId, weekStart],
    );
  }

  // Future<void> removeEmployeeFromWeek(int employeeId, int weekStart) async {
  //   final db = await database;

  //   // First remove from week assignments
  //   final deletedAssignments = await db.delete(
  //     'week_assignments',
  //     where: 'employee_id = ? AND week_start = ?',
  //     whereArgs: [employeeId, weekStart],
  //   );

  //   // Then remove any shift data
  //   final deletedShifts = await db.delete(
  //     'shift_timings',
  //     where: 'employee_id = ? AND week_start = ?',
  //     whereArgs: [employeeId, weekStart],
  //   );

  //   print(
  //     '🗑️ Removed $deletedAssignments assignments and $deletedShifts shifts',
  //   );
  // }

  Future<void> _migrateToVersion2(Database db) async {
    try {
      // Drop and recreate shift_timings table to update schema for start_time and end_time as INTEGER
      await db.execute('DROP TABLE IF EXISTS shift_timings');

      await db.execute('''
  CREATE TABLE shift_timings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    day TEXT NOT NULL,
    week_start INTEGER NOT NULL,
    shift_name TEXT,
    start_time INTEGER,
    end_time INTEGER,
    FOREIGN KEY (employee_id) REFERENCES employees (employee_id) ON DELETE CASCADE,
    UNIQUE(employee_id, day, week_start) ON CONFLICT REPLACE
  )
''');
    } catch (e) {
      print('Migration to v2 failed: $e — recreating tables.');
      await db.execute('DROP TABLE IF EXISTS shift_timings');

      await db.execute('''
  CREATE TABLE shift_timings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    day TEXT NOT NULL,
    week_start INTEGER NOT NULL,
    shift_name TEXT,
    start_time INTEGER,
    end_time INTEGER,
    FOREIGN KEY (employee_id) REFERENCES employees (employee_id) ON DELETE CASCADE,
    UNIQUE(employee_id, day, week_start) ON CONFLICT REPLACE
  )
''');
    }
  }

  // ───── Employees ─────
  Future<int> insertEmployee(String name) async {
    final db = await database;
    return await db.insert('employees', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final db = await database;
    return await db.query('employees');
  }

  Future<void> deleteEmployee(int id) async {
    final db = await database;
    await db.delete('employees', where: 'employee_id = ?', whereArgs: [id]);
  }

  // ───── Week Info ─────
  Future<int> insertWeekInfo(Map<String, dynamic> weekInfo) async {
    final db = await database;
    return await db.insert('week_info', weekInfo);
  }

  Future<List<Map<String, dynamic>>> getWeekInfo() async {
    final db = await database;
    return await db.query('week_info');
  }

  // Add this method to your DatabaseHelper class
  Future<void> deleteShiftsForEmployee(int employeeId) async {
    final db = await database;
    await db.delete(
      'shift_timings',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
    );
  }

  // ───── Shift Timings ─────
  Future<void> insertOrUpdateShift({
    required int employeeId,
    required String day,
    required int weekStart,
    String? shiftName,
    int? startTime,
    int? endTime,
  }) async {
    final db = await database;

    await db.insert('shift_timings', {
      'employee_id': employeeId,
      'day': day.toLowerCase(),
      'week_start': weekStart,
      'shift_name': shiftName,
      'start_time': startTime,
      'end_time': endTime,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateShiftTiming(
    int employeeId,
    String day,
    int weekStart,
    String shiftValue,
  ) async {
    final parts = shiftValue.split('|');
    final shiftName = parts[0];
    int startTimeMillis = 0;
    int endTimeMillis = 0;

    if (parts.length > 1 && parts[1].contains('-')) {
      final timeParts = parts[1].split('-');
      if (timeParts.length == 2) {
        // Parse start and end time strings "HH:mm" to milliseconds since epoch for the weekStart day
        final startParts = timeParts[0].split(':');
        final endParts = timeParts[1].split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final startHour = int.tryParse(startParts[0]) ?? 0;
          final startMinute = int.tryParse(startParts[1]) ?? 0;
          final endHour = int.tryParse(endParts[0]) ?? 0;
          final endMinute = int.tryParse(endParts[1]) ?? 0;

          final startDateTime = DateTime.fromMillisecondsSinceEpoch(
            weekStart,
          ).add(Duration(hours: startHour, minutes: startMinute));
          final endDateTime = DateTime.fromMillisecondsSinceEpoch(
            weekStart,
          ).add(Duration(hours: endHour, minutes: endMinute));

          startTimeMillis = startDateTime.millisecondsSinceEpoch;
          endTimeMillis = endDateTime.millisecondsSinceEpoch;
        }
      }
    }

    await insertOrUpdateShift(
      employeeId: employeeId,
      day: day.toLowerCase(),
      weekStart: weekStart,
      shiftName: shiftName,
      startTime: startTimeMillis,
      endTime: endTimeMillis,
    );
  }

  Future<List<Map<String, dynamic>>> getShiftsForWeek(int weekStart) async {
    final db = await database;
    try {
      return await db.query(
        'shift_timings',
        where: 'week_start = ?',
        whereArgs: [weekStart],
      );
    } catch (e) {
      print('Error getting shifts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeesWithShiftsForWeek(
    int weekStart,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT 
      e.employee_id,
      e.name,
      st.day,
      st.shift_name,
      st.start_time,
      st.end_time
    FROM employees e
    JOIN week_assignments wa ON e.employee_id = wa.employee_id AND wa.week_start = ?
    LEFT JOIN shift_timings st ON e.employee_id = st.employee_id AND st.week_start = ?
    ORDER BY e.employee_id, st.day
  ''',
      [weekStart, weekStart],
    );
  }

  Future<List<Map<String, dynamic>>> getShiftTimings() async {
    final db = await database;
    return await db.query('shift_timings');
  }

  // ───── Debug Tools ─────
  Future<void> debugPrintSchema() async {
    final db = await database;
    print('📊 Database version: ${await db.getVersion()}');
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    print('📋 All tables:');
    for (var table in tables) {
      final tableName = table['name'];
      print(' - $tableName');
      final columns = await db.rawQuery("PRAGMA table_info($tableName)");
      for (var column in columns) {
        print('   ${column['name']} (${column['type']})');
      }
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<List<Map<String, dynamic>>> getShiftsForEmployeeWeek(int employeeId, int weekStart) async {
    final db = await database;
    try {
      return await db.query(
        'shift_timings',
        where: 'employee_id = ? AND week_start = ?',
        whereArgs: [employeeId, weekStart],
      );
    } catch (e) {
      print('Error getting shifts for employee $employeeId: $e');
      return [];
    }
  }
}
