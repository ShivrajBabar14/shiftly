import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

class ShiftlyProScreen extends StatefulWidget {
  @override
  State<ShiftlyProScreen> createState() => _ShiftlyProScreenState();
}

class _ShiftlyProScreenState extends State<ShiftlyProScreen> {
  String selectedPlan = '';
  int selectedAmount = 0; // Amount in rupees
  late InAppPurchase _inAppPurchase;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  List<GooglePlayProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _inAppPurchase = InAppPurchase.instance;
    _initializePurchaseStream();
    _loadProducts();
  }

  // Initialize the purchase stream and handle updates
  void _initializePurchaseStream() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    });
  }

  // Handle purchase updates (success, failure, etc.)
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _verifyPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle errors here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${purchaseDetails.error?.message}'),
          ),
        );
      }
    }
  }

  // Verify the purchase (this should be done on your backend ideally)
  void _verifyPurchase(PurchaseDetails purchaseDetails) {
    // Acknowledge the purchase on Google Play
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
    // You can also check if the product is valid and grant the user access here
    // For example, provide them with the "Shiftly Pro" features.
    print('Purchase successful: ${purchaseDetails.productID}');
  }

  // Query the available products (Monthly, Annually)
  Future<void> _loadProducts() async {
    const Set<String> _kIds = {
      'shiftwise_monthly',
      'shiftwise_yearly',
    }; // Product IDs from Google Play
    ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
      _kIds,
    );

    if (response.notFoundIDs.isNotEmpty) {
      // Handle the case where some products are not found
      print("Products not found: ${response.notFoundIDs}");
    }

    setState(() {
      _products = response.productDetails
          .whereType<GooglePlayProductDetails>()
          .toList();
    });
  }

  Future<void> _startPurchase(String productId) async {
    // Find the product matching the productId
    final GooglePlayProductDetails product = _products.firstWhere(
      (product) => product.id == productId,
      orElse: () {
        throw 'Product with ID $productId not found!';
      },
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    // Initiate the purchase flow
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close icon
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 28),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Center(
                child: Text(
                  'Shiftly Pro',
                  style: GoogleFonts.questrial(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Feature list
              buildFeature(
                assetPath: 'assets/users.png',
                title: 'Unlimited Employee Access',
                subtitle:
                    'Add more than 5 employees to your team with a paid plan',
              ),
              const SizedBox(height: 25),
              buildFeature(
                assetPath: 'assets/backup.png',
                title: 'Auto Backup',
                subtitle: 'Keep your data safe with automatic backup feature',
              ),
              const SizedBox(height: 25),
              buildFeature(
                assetPath: 'assets/schedule.png',
                title: 'Unlimited Employee Access',
                subtitle:
                    'Add more than 5 employees to your team with a paid plan',
              ),

              const SizedBox(height: 50),

              // Pricing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildPriceCard(
                    price: _getPriceForProduct('shiftwise_monthly'),
                    label: 'Monthly',
                    isSelected: selectedPlan == 'Monthly',
                    onTap: () {
                      setState(() {
                        selectedPlan = 'Monthly';
                      });
                    },
                  ),
                  buildPriceCard(
                    price: _getPriceForProduct('shiftwise_yearly'),
                    label: 'Annually',
                    isSelected: selectedPlan == 'Annually',
                    onTap: () {
                      setState(() {
                        selectedPlan = 'Annually';
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Go Pro button
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
                    if (selectedPlan.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a plan.')),
                      );
                      return;
                    }

                    // Trigger purchase based on the selected plan
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
            ],
          ),
        ),
      ),
    );
  }

  String _getPriceForProduct(String productId) {
    try {
      final GooglePlayProductDetails product = _products.firstWhere(
        (product) => product.id == productId,
      );
      return product.price;
    } catch (e) {
      return '₹ 0.00';
    }
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
          backgroundColor: Color(0xFFE5DCF4),
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
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.questrial(
                  fontSize: 14,
                  color: Color(0xFF616161),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
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
            Text(
              label,
              style: GoogleFonts.questrial(
                fontSize: 14,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
