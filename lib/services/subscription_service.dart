import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal();

  final StreamController<bool> _subscriptionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get subscriptionStatusStream => _subscriptionStatusController.stream;

  bool _isSubscribed = false;

  bool get isSubscribed => _isSubscribed;

  Future<void> loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool('isSubscribed') ?? false;
    print('DEBUG: SubscriptionService loaded isSubscribed: $_isSubscribed');
    _subscriptionStatusController.add(_isSubscribed);
  }

  Future<void> setSubscriptionStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSubscribed', status);
    print('DEBUG: SubscriptionService setSubscriptionStatus called with: $status');
    _isSubscribed = status;
    _subscriptionStatusController.add(_isSubscribed);
  }

  void dispose() {
    _subscriptionStatusController.close();
  }
}
