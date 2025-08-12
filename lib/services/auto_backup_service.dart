import 'dart:async';
import 'package:Shiftwise/db/database_helper.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AutoBackupService {
  Timer? _backupTimer;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  void startAutoBackup() {
    // Backup every 2 hours (7200 seconds)
    _backupTimer = Timer.periodic(Duration(hours: 8), (timer) async {
      final dbHelper = DatabaseHelper();
      bool success = await dbHelper.backupDatabase();
      if (success) {
        print('Automatic database backup completed.');
        // 📊 Log success event
        await analytics.logEvent(
          name: 'auto_backup',
          parameters: {
            'status': 'success',
            'interval_hours': 8,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } else {
        print('Automatic database backup failed.');
        // 📊 Log failure event
        await analytics.logEvent(
          name: 'auto_backup',
          parameters: {
            'status': 'failed',
            'interval_hours': 8,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    });
  }

  void stopAutoBackup() {
    _backupTimer?.cancel();
  }
}
