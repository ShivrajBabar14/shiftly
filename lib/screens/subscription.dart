import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/success.dart';
import 'package:Shiftwise/services/subscription_service.dart';

class ShiftlyProScreen extends StatefulWidget {
  @override
  State<ShiftlyProScreen> createState() => _ShiftlyProScreenState();
}

class _ShiftlyProScreenState extends State<ShiftlyProScreen> {
  String selectedPlan = 'Annually';
  late InAppPurchase _inAppPurchase;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  List<GooglePlayProductDetails> _products = [];
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _inAppPurchase = InAppPurchase.instance;
    _initializePurchaseStream();
    _loadProducts();
    _restoreSubscriptionStatus();
    _refreshSubscriptionStatus();
  }

  Future<void> _restoreSubscriptionStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) return;
    await InAppPurchase.instance.restorePurchases();
    final bool? storedStatus = prefs.getBool('isSubscribed');
    setState(() {
      isSubscribed = storedStatus ?? false;
    });
  }

  Future<void> _refreshSubscriptionStatus() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Play services not available')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Restore purchases to get latest subscription status
      await InAppPurchase.instance.restorePurchases();
      
      // Wait for the purchase stream to process
      await Future.delayed(const Duration(seconds: 2));
      
      // Close loading indicator
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription status refreshed')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing: ${e.toString()}')),
        );
      }
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool activeSubscriptionFound = false;
    String subscriptionType = '';
    String orderId = '';
    String purchaseToken = '';
    String purchaseDate = '';

    print('DEBUG: Purchase details list received: $purchaseDetailsList');

    for (var purchaseDetails in purchaseDetailsList) {
      print('DEBUG: PurchaseDetails status: ${purchaseDetails.status}, productID: ${purchaseDetails.productID}');
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == 'shiftwise_monthly' ||
            purchaseDetails.productID == 'shiftwise_yearly') {
          activeSubscriptionFound = true;
          subscriptionType = purchaseDetails.productID == 'shiftwise_monthly' ? 'Monthly' : 'Yearly';
          orderId = purchaseDetails.purchaseID ?? '';
          purchaseToken = purchaseDetails.verificationData.serverVerificationData ?? '';
          purchaseDate = purchaseDetails.transactionDate?.toString() ?? '';
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
      }
    }

    await prefs.setBool('isSubscribed', activeSubscriptionFound);
    await prefs.setString('subscriptionType', subscriptionType);
    await prefs.setString('orderId', orderId);
    await prefs.setString('purchaseToken', purchaseToken);
    await prefs.setString('purchaseDate', purchaseDate);

    // Update subscription service status
    await SubscriptionService().setSubscriptionStatus(activeSubscriptionFound);

    setState(() {
      isSubscribed = activeSubscriptionFound;
    });

    if (activeSubscriptionFound && mounted) {
      // Close subscription screen and return to home
      Navigator.pop(context, true); // Return true to indicate subscription success
    }
  }

  void _initializePurchaseStream() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    });
  }

  Future<void> _loadProducts() async {
    const Set<String> _kIds = {'shiftwise_monthly', 'shiftwise_yearly'};
    ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kIds);
    setState(() {
      _products = response.productDetails
          .whereType<GooglePlayProductDetails>()
          .toList();
    });
  }

  Future<void> _startPurchase(String productId) async {
    final GooglePlayProductDetails product = _products.firstWhere(
      (product) => product.id == productId,
      orElse: () => throw 'Product with ID $productId not found!',
    );
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  String _getPriceForProduct(String productId) {
    try {
      final product = _products.firstWhere(
        (product) => product.id == productId,
      );
      return product.price;
    } catch (e) {
      return '₹ 0.00';
    }
  }

  double? _calculateDiscountPercentage() {
    try {
      final monthly = _products.firstWhere((p) => p.id == 'shiftwise_monthly');
      final yearly = _products.firstWhere((p) => p.id == 'shiftwise_yearly');
      final monthlyPrice = double.parse(monthly.rawPrice.toString());
      final yearlyPrice = double.parse(yearly.rawPrice.toString());
      final fullYearPrice = monthlyPrice * 12;
      final discount = 100 - ((yearlyPrice / fullYearPrice) * 100);
      return discount;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final discount = _calculateDiscountPercentage();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 28),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Shiftwise Pro',
                  style: GoogleFonts.questrial(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isSubscribed)
                Center(
                  child: TextButton.icon(
                    onPressed: _refreshSubscriptionStatus,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Status'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              buildFeature(
                assetPath: 'assets/users.png',
                title: 'Unlimited Employee Access',
                subtitle: 'Add more than 5 employees to your team with a paid plan',
              ),
              const SizedBox(height: 35),
              buildFeature(
                assetPath: 'assets/backup.png',
                title: 'Auto Backup',
                subtitle: 'Keep your data safe with automatic backup feature',
              ),
              const SizedBox(height: 35),
              buildFeature(
                assetPath: 'assets/schedule.png',
                title: 'Advanced Shift Scheduling',
                subtitle: 'Create shifts for the upcoming weeks in advance.',
              ),
              const SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildPriceCard(
                    price: _getPriceForProduct('shiftwise_monthly'),
                    label: 'Monthly',
                    isSelected: selectedPlan == 'Monthly',
                    onTap: () => setState(() => selectedPlan = 'Monthly'),
                  ),
                  buildPriceCard(
                    price: _getPriceForProduct('shiftwise_yearly'),
                    label: 'Annually',
                    isSelected: selectedPlan == 'Annually',
                    onTap: () => setState(() => selectedPlan = 'Annually'),
                    badge: discount != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Save ${discount!.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (selectedPlan == 'Monthly') {
                      _startPurchase('shiftwise_monthly');
                    } else if (selectedPlan == 'Annually') {
                      _startPurchase('shiftwise_yearly');
                    }
                  },
                  child: Text(
                    'Go Pro',
                    style: GoogleFonts.questrial(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFeature({
    required String assetPath,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE5DCF4),
          child: Image.asset(
            assetPath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.questrial(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.questrial(
                  fontSize: 14,
                  color: const Color(0xFF616161),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildPriceCard({
    required String price,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? Colors.deepPurple.withOpacity(0.1)
                  : Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price,
                  style: GoogleFonts.questrial(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(bottom: label == 'Annually' ? 4 : 4),
                  child: Text(
                    label,
                    style: GoogleFonts.questrial(
                      fontSize: 14,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                SizedBox(height: badge != null ? 1 : 0),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              bottom: -14,
              left: 0,
              right: 0,
              child: Center(child: badge),
            ),
        ],
      ),
    );
  }
}