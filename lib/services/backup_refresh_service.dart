import 'package:flutter/foundation.dart';
import 'data_refresh_service.dart';
import '../db/database_helper.dart';

class BackupRefreshService extends ChangeNotifier {
  static final BackupRefreshService _instance = 
      BackupRefreshService._internal();
  factory BackupRefreshService() => _instance;
  BackupRefreshService._internal();

  final DataRefreshService _refreshService = DataRefreshService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Trigger refresh after successful backup restore
  Future<void> refreshAfterRestore() async {
    try {
      // Force refresh all data
      _refreshService.refreshAll();
      
      // Notify listeners that data has been refreshed
      notifyListeners();
      
      // Log the refresh
      if (kDebugMode) {
        print('✅ Data refreshed after backup restore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing after restore: $e');
      }
    }
  }

  /// Trigger refresh after successful backup
  Future<void> refreshAfterBackup() async {
    try {
      // Refresh data to ensure latest state is backed up
      _refreshService.refreshAll();
      
      if (kDebugMode) {
        print('✅ Data refreshed before backup');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing after backup: $e');
      }
    }
  }

  /// Auto-refresh current week data without manual intervention
  Future<void> autoRefreshCurrentWeek() async {
    try {
      final weekStart = DateTime.now()
          .subtract(Duration(days: DateTime.now().weekday - 1))
          .millisecondsSinceEpoch;
      
      // Force refresh for current week
      _refreshService.refreshSchedules();
      
      if (kDebugMode) {
        print('✅ Auto-refreshed current week data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error auto-refreshing current week: $e');
      }
    }
  }
}
