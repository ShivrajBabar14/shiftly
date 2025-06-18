import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _databaseVersion = 2;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'shiftly.db');

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

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 2:
          await _migrateToVersion2(db);
          break;
        // Future migrations go here
      }
    }
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
        start_time TEXT,
        end_time TEXT,
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
  }

  Future<void> _migrateToVersion2(Database db) async {
    try {
      // Add week_start column if needed
      final columns = await db.rawQuery("PRAGMA table_info(shift_timings)");
      final columnNames = columns.map((e) => e['name']).toList();

      if (!columnNames.contains('week_start')) {
        await db.execute('ALTER TABLE shift_timings ADD COLUMN week_start INTEGER DEFAULT 0');
      }
    } catch (e) {
      // If migration fails, recreate
      print('Migration to v2 failed: $e — recreating tables.');
      await db.execute('DROP TABLE IF EXISTS shift_timings');
      await _createTables(db);
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

  // ───── Shift Timings ─────
  Future<void> insertOrUpdateShift({
    required int employeeId,
    required String day,
    required int weekStart,
    required String shiftName,
    required String startTime,
    required String endTime,
  }) async {
    final db = await database;

    await db.insert(
      'shift_timings',
      {
        'employee_id': employeeId,
        'day': day.toLowerCase(),
        'week_start': weekStart,
        'shift_name': shiftName,
        'start_time': startTime,
        'end_time': endTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateShiftTiming(int employeeId, String day, int weekStart, String shiftValue) async {
    final parts = shiftValue.split('|');
    final shiftName = parts[0];
    String startTime = '';
    String endTime = '';

    if (parts.length > 1 && parts[1].contains('-')) {
      final timeParts = parts[1].split('-');
      if (timeParts.length == 2) {
        startTime = timeParts[0];
        endTime = timeParts[1];
      }
    }

    await insertOrUpdateShift(
      employeeId: employeeId,
      day: day.toLowerCase(),
      weekStart: weekStart,
      shiftName: shiftName,
      startTime: startTime,
      endTime: endTime,
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
      return await db.query('shift_timings');
    }
  }

  Future<List<Map<String, dynamic>>> getShiftTimings() async {
    final db = await database;
    return await db.query('shift_timings');
  }

  // ───── Debug Tools ─────
  Future<void> debugPrintSchema() async {
    final db = await database;
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    for (var table in tables) {
      final tableName = table['name'];
      final columns = await db.rawQuery("PRAGMA table_info($tableName)");
      print('Table: $tableName');
      for (var column in columns) {
        print('  ${column['name']} (${column['type']})');
      }
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
