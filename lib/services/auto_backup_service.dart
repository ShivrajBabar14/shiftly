import 'dart:async';
import 'package:shiftly/db/database_helper.dart';

class AutoBackupService {
  Timer? _backupTimer;

  void startAutoBackup() {
    // Backup every 2 hours (7200 seconds)
    _backupTimer = Timer.periodic(Duration(hours: 2), (timer) async {
      final dbHelper = DatabaseHelper();
      bool success = await dbHelper.backupDatabase();
      if (success) {
        print('Automatic database backup completed.');
      } else {
        print('Automatic database backup failed.');
      }
    });
  }

  void stopAutoBackup() {
    _backupTimer?.cancel();
  }
}
