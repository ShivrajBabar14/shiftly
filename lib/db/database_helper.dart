import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Shiftwise/models/employee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Shiftwise/services/data_refresh_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _databaseVersion = 4;

  final DataRefreshService _dataRefreshService = DataRefreshService();

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
  // Future<bool> backupDatabase() async {
  //   try {
  //     final dbPath = await getDatabasesPath();
  //     final dbFile = File(join(dbPath, 'shiftly.db'));

  //     // Get public documents directory
  //     final directories = await getExternalStorageDirectories(type: StorageDirectory.documents);
  //     if (directories == null || directories.isEmpty) {
  //       print('❌ Could not access public documents directory');
  //       return false;
  //     }
  //     final directory = directories.first;

  //     final publicBackupDir = Directory(join(directory.path, 'ShiftlyBackups'));
  //     if (!await publicBackupDir.exists()) {
  //       await publicBackupDir.create(recursive: true);
  //     }

  //     final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  //     final backupFile = File(join(publicBackupDir.path, 'shiftly_backup_$timestamp.db'));

  //     await dbFile.copy(backupFile.path);
  //     print('✅ Database backed up to ${backupFile.path}');
  //     return true;
  //   } catch (e) {
  //     print('❌ Error during database backup: $e');
  //     return false;
  //   }
  // }

  Future<bool> backupDatabase() async {
    try {
      // Get the original database file path consistent with _initDatabase()
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = join(directory.path, 'Shiftwise', 'Shiftwise.db');
      final dbFile = File(dbPath);

      // Use hardcoded public Documents directory path for backup storage
      final backupDirectory = Directory('/storage/emulated/0/Documents');
      final backupDir = Directory(
        join(backupDirectory.path, 'Shiftwise', 'Backup'),
      );

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
        print('📁 Created backup directory: ${backupDir.path}');
      }

      // Generate date string for backup filename (YYYY-MM-DD)
      final now = DateTime.now();
      final dateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Construct backup file path for today's backup
      final backupFilePath = join(
        backupDir.path,
        'Shiftwise_backup_$dateStr.db',
      );
      final backupFile = File(backupFilePath);

      // Check if backup file for today exists before deleting
      if (await backupFile.exists()) {
        try {
          await backupFile.delete();
          print('🗑️ Deleted existing backup file for today: $backupFilePath');
        } catch (e) {
          print('⚠️ Failed to delete existing backup file: $e');
        }
      }

      // Copy the database to backup location
      await dbFile.copy(backupFile.path);
      final backupExists = await backupFile.exists();
      if (backupExists) {
        final fileStat = await backupFile.stat();
        print('✅ Database backed up to ${backupFile.path}');
        print('Backup file size: ${fileStat.size} bytes');
        print('Backup file modified: ${fileStat.modified}');
      } else {
        print('❌ Backup file does not exist after copy operation.');
      }
      return backupExists;
    } catch (e) {
      print('❌ Error during database backup: $e');
      return false;
    }
  }

  // Restore latest backup from backups folder
  Future<bool> restoreLatestBackup() async {
    try {
      // Use hardcoded public Documents directory path for backup storage
      final backupDirectory = Directory('/storage/emulated/0/Documents');
      final backupDir = Directory(
        join(backupDirectory.path, 'Shiftwise', 'Backup'),
      );

      if (!await backupDir.exists()) {
        print('❌ Backup directory does not exist.');
        return false;
      }

      // List all .db files (backups) in the directory
      final backups = backupDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.db'))
          .toList();

      if (backups.isEmpty) {
        print('❌ No backup files found.');
        return false;
      }

      // Sort backups by modification date (latest first)
      backups.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      final latestBackup = backups.first;

      // Get current database file path consistent with _initDatabase()
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = join(directory.path, 'Shiftwise', 'Shiftwise.db');
      final dbFile = File(dbPath);

      // Delete existing database if it exists
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Copy backup to database location
      await latestBackup.copy(dbFile.path);
      print('✅ Database restored from ${latestBackup.path}');

      // Reinitialize the database connection
      _database = await _initDatabase();

      // Notify listeners to refresh data
      _dataRefreshService.refreshAll();

      return true;
    } catch (e) {
      print('❌ Error during database restore: $e');
      return false;
    }
  }

  // Restore database from a specific file path
  Future<bool> restoreFromFile(String filePath) async {
    Database? sourceDb;
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ Specified backup file does not exist.');
        return false;
      }

      // Close existing database connection if open
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final dbPath = join(directory.path, 'Shiftwise', 'Shiftwise.db');
      print('Target database path: $dbPath');

      // Reopen target database with write access
      final targetDb = await openDatabase(dbPath);

      // Open the source database (selected file)
      sourceDb = await openDatabase(filePath, readOnly: true);

      // Get list of tables in source database
      final tables = await sourceDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
      );

      // For each table, copy data to target database
      for (final tableMap in tables) {
        final tableName = tableMap['name'] as String;

        // Skip android_metadata table to avoid readonly errors
        if (tableName == 'android_metadata') {
          continue;
        }

        // Query all rows from source table
        final rows = await sourceDb.query(tableName);

        // Insert or replace rows into target table
        for (final row in rows) {
          // Remove any keys that are not columns in the target table to avoid errors
          final filteredRow = Map<String, dynamic>.from(row);
          // Remove 'rowid' or other special keys if present
          filteredRow.remove('rowid');
          await targetDb.insert(
            tableName,
            filteredRow,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      print('✅ Database restored from $filePath by importing data.');

      // Close and reopen the target database to refresh connection
      await targetDb.close();
      _database = await _initDatabase();

      // Notify listeners to refresh data
      _dataRefreshService.refreshAll();

      return true;
    } catch (e) {
      print('❌ Error during database restore from file: $e');
      return false;
    } finally {
      if (sourceDb != null) {
        await sourceDb.close();
      }
    }
  }

  // New method for automatic data refresh after restore
  Future<void> refreshDataAfterRestore() async {
    // Force close and reopen database connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _database = await _initDatabase();
  }

  Future<bool> checkStoragePermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      } else {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          // Open app settings for user to manually grant permission
          await openAppSettings();
          return false;
        } else if (status.isDenied) {
          // Request legacy storage permission for Android 10 and below
          final legacyStatus = await Permission.storage.request();
          return legacyStatus.isGranted;
        }
        return false;
      }
    }
    return true; // For iOS, permissions work differently
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

  Future<DateTime?> getLastBackupDate() async {
    try {
      final backupDirectory = Directory('/storage/emulated/0/Documents');
      final backupDir = Directory(
        join(backupDirectory.path, 'Shiftwise', 'Backup'),
      );

      if (!await backupDir.exists()) {
        print('Backup directory does not exist.');
        return null;
      }

      final backups = backupDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.db'))
          .toList();

      if (backups.isEmpty) {
        print('No backup files found.');
        return null;
      }

      backups.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      final latestBackup = backups.first;
      final fileStat = await latestBackup.stat();
      return fileStat.modified;
    } catch (e) {
      print('Error getting last backup date: $e');
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'Shiftwise', 'Shiftwise.db');

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
        'status': null,
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
        status TEXT,
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
    status TEXT,
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
    status TEXT,
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
    String? status,
  }) async {
    final db = await database;

    await db.insert('shift_timings', {
      'employee_id': employeeId,
      'day': day.toLowerCase(),
      'week_start': weekStart,
      'shift_name': shiftName,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateShiftTiming(
    int employeeId,
    String day,
    int weekStart,
    String shiftValue, {
    String status = 'active', // <-- New optional param
  }) async {
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
      status: status,
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
      st.end_time,
      st.status
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

  Future<List<Map<String, dynamic>>> getShiftsForEmployeeWeek(
    int employeeId,
    int weekStart,
  ) async {
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

  // Get all unique shift patterns from all weeks for suggestions
  Future<List<Map<String, dynamic>>> getAllShiftSuggestions() async {
    final db = await database;
    try {
      return await db.rawQuery('''
      SELECT DISTINCT 
        shift_name,
        start_time,
        end_time
      FROM shift_timings
      WHERE shift_name IS NOT NULL 
        AND shift_name != ''
      ORDER BY shift_name
    ''');
    } catch (e) {
      print('Error getting all shift suggestions: $e');
      return [];
    }
  }
}
