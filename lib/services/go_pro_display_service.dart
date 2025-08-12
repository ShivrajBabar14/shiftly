import 'package:shared_preferences/shared_preferences.dart';
import 'package:Shiftwise/services/subscription_service.dart';

class GoProDisplayService {
  static const String _lastShownKey = 'go_pro_last_shown_timestamp';
  static const String _closeTimestampKey = 'go_pro_close_timestamp';
  
  // 48 hours in milliseconds
  static const int _fortyEightHoursInMs = 48 * 60 * 60 * 1000;
  
  /// Check if Go Pro page should be shown for free users
  static Future<bool> shouldShowGoProPage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user is subscribed
    await SubscriptionService().loadSubscriptionStatus();
    final isSubscribed = SubscriptionService().isSubscribed;
    
    if (isSubscribed) {
      // Reset timestamps for subscribed users
      await prefs.remove(_lastShownKey);
      await prefs.remove(_closeTimestampKey);
      return false;
    }
    
    // Check last shown timestamp
    final lastShown = prefs.getInt(_lastShownKey) ?? 0;
    final closeTimestamp = prefs.getInt(_closeTimestampKey) ?? 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // If never shown, show immediately
    if (lastShown == 0) {
      return true;
    }
    
    // If user closed the page, check 48 hours from close time
    if (closeTimestamp > 0) {
      return (now - closeTimestamp) >= _fortyEightHoursInMs;
    }
    
    // Otherwise check 48 hours from last shown
    return (now - lastShown) >= _fortyEightHoursInMs;
  }
  
  /// Record when Go Pro page was shown
  static Future<void> recordGoProShown() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastShownKey, now);
  }
  
  /// Record when user closed the Go Pro page
  static Future<void> recordGoProClosed() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_closeTimestampKey, now);
  }

  /// Handle navigation after closing Go Pro page
  static Future<void> handleGoProClose() async {
    // Record close timestamp
    await recordGoProClosed();
    
    // Navigate to home screen
    // This will be handled by the navigation logic in the UI
  }
  
  /// Get remaining time until next display (in hours)
  static Future<double> getRemainingHours() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_lastShownKey) ?? 0;
    final closeTimestamp = prefs.getInt(_closeTimestampKey) ?? 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final referenceTime = closeTimestamp > 0 ? closeTimestamp : lastShown;
    
    if (referenceTime == 0) return 0;
    
    final elapsed = now - referenceTime;
    final remaining = _fortyEightHoursInMs - elapsed;
    
    return remaining > 0 ? remaining / (60 * 60 * 1000) : 0;
  }
}
