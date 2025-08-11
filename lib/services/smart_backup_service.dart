import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:Shiftwise/services/subscription_service.dart';
import 'package:Shiftwise/db/database_helper.dart';

class SmartBackupService {
  static final SmartBackupService _instance = SmartBackupService._internal();
  Timer? _backupTimer;
  bool _isInitialized = false;

  factory SmartBackupService() => _instance;
  SmartBackupService._internal();

  /// Initialize the smart backup service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔧 Initializing Smart Backup Service...');
    
    // Check and perform backup on app start
    await _checkAndPerformBackupOnStart();
    
    // Start 8-hour periodic backup timer
    _startPeriodicBackup();
    
    _isInitialized = true;
  }

  /// Check subscription status
  Future<bool> _isUserSubscribed() async {
    return SubscriptionService().isSubscribed;
  }

  /// Check if backup should be performed on app start
  Future<void> _checkAndPerformBackupOnStart() async {
    final isSubscribed = await _isUserSubscribed();
    
    if (!isSubscribed) {
      print('⏭️ User not subscribed, skipping backup check on start');
      return;
    }

    final shouldBackup = await _shouldPerformBackup();
    
    if (shouldBackup) {
      print('📱 App start detected - performing backup check...');
      await _performSmartBackup();
    } else {
      print('✅ Backup not needed on app start');
    }
  }

  /// Start 8-hour periodic backup timer
  void _startPeriodicBackup() {
    _backupTimer?.cancel();
    
    // Check every 8 hours (28800 seconds)
    _backupTimer = Timer.periodic(const Duration(hours: 8), (timer) async {
      final isSubscribed = await _isUserSubscribed();
      
      if (!isSubscribed) {
        print('⏭️ User not subscribed, skipping periodic backup');
        return;
      }

      final shouldBackup = await _shouldPerformBackup();
      
      if (shouldBackup) {
        print('⏰ 8-hour interval reached - performing backup...');
        await _performSmartBackup();
      }
    });
    
    print('⏰ Started 8-hour periodic backup timer');
  }

  /// Determine if backup should be performed
  Future<bool> _shouldPerformBackup() async {
    final lastBackupDate = await DatabaseHelper().getLastBackupDate();
    
    if (lastBackupDate == null) {
      print('🆕 No backup found - backup needed');
      return true;
    }

    final now = DateTime.now();
    final difference = now.difference(lastBackupDate);
    
    // Check if it's been more than 8 hours
    if (difference.inHours >= 8) {
      print('⏰ Last backup was ${difference.inHours} hours ago - backup needed');
      return true;
    }

    // Check if last backup is from yesterday
    final lastBackupDay = DateTime(
      lastBackupDate.year,
      lastBackupDate.month,
      lastBackupDate.day,
    );
    
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );
    
    if (lastBackupDay.isBefore(today)) {
      print('📅 Last backup is from yesterday - new backup needed');
      return true;
    }

    print('✅ Backup not needed - last backup was ${difference.inHours} hours ago');
    return false;
  }

  /// Perform the actual backup with smart logic
  Future<bool> _performSmartBackup() async {
    try {
      final success = await DatabaseHelper().backupDatabase();
      
      if (success) {
        print('✅ Smart backup completed successfully');
      } else {
        print('❌ Smart backup failed');
      }
      
      return success;
    } catch (e) {
      print('❌ Error during smart backup: $e');
      return false;
    }
  }

  /// Force backup regardless of conditions (for manual triggers)
  Future<bool> forceBackup() async {
    final isSubscribed = await _isUserSubscribed();
    
    if (!isSubscribed) {
      print('❌ Cannot force backup - user not subscribed');
      return false;
    }
    
    return await _performSmartBackup();
  }

  /// Get backup status information
  Future<Map<String, dynamic>> getBackupStatus() async {
    final lastBackupDate = await DatabaseHelper().getLastBackupDate();
    final isSubscribed = await _isUserSubscribed();
    
    if (lastBackupDate == null) {
      return {
        'hasBackup': false,
        'lastBackupDate': null,
        'hoursSinceLastBackup': null,
        'nextBackupDue': true,
        'isSubscribed': isSubscribed,
      };
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastBackupDate);
    
    return {
      'hasBackup': true,
      'lastBackupDate': lastBackupDate,
      'hoursSinceLastBackup': difference.inHours,
      'nextBackupDue': difference.inHours >= 8 || 
                      DateTime(lastBackupDate.year, lastBackupDate.month, lastBackupDate.day)
                          .isBefore(DateTime(now.year, now.month, now.day)),
      'isSubscribed': isSubscribed,
    };
  }

  /// Stop the backup service
  void dispose() {
    _backupTimer?.cancel();
    _backupTimer = null;
    _isInitialized = false;
    print('🛑 Smart Backup Service stopped');
  }

  /// Restart the backup service (useful after subscription changes)
  Future<void> restart() async {
    dispose();
    await initialize();
  }
}
