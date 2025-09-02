import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal() {
    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(_listenToPurchaseUpdated);
  }

  final StreamController<bool> _subscriptionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get subscriptionStatusStream => _subscriptionStatusController.stream;

  bool _isSubscribed = false;

  bool get isSubscribed => _isSubscribed;

  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

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

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    bool activeSubscriptionFound = false;

    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == 'shiftwise_monthly' || purchaseDetails.productID == 'shiftwise_yearly') {
          activeSubscriptionFound = true;
          break;
        }
      }
    }

    await setSubscriptionStatus(activeSubscriptionFound);
  }

  Future<void> refreshSubscriptionStatus() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      print('DEBUG: Google Play services not available');
      await setSubscriptionStatus(false);
      return;
    }

    // Restore purchases to refresh purchase stream
    await InAppPurchase.instance.restorePurchases();

    // Wait for purchase stream to process updates
    await Future.delayed(const Duration(seconds: 2));

    // Subscription status will be updated via purchase stream listener
  }

  void dispose() {
    _purchaseSubscription.cancel();
    _subscriptionStatusController.close();
  }
}