import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ShiftlyProScreen extends StatefulWidget {
  @override
  State<ShiftlyProScreen> createState() => _ShiftlyProScreenState();
}

class _ShiftlyProScreenState extends State<ShiftlyProScreen> {
  late Razorpay _razorpay;
  String selectedPlan = '';
  int selectedAmount = 0; // Amount in paisa

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _startPayment(int amount, String planType) {
    var options = {
      'key': 'rzp_test_K2K20arHghyhnD', // Razorpay test key
      'amount': amount * 100, // Razorpay amount is in paisa
      'name': 'Shiftly Pro',
      'description': planType,
      'prefill': {'contact': '9123456789', 'email': 'testuser@example.com'},
      'theme': {'color': '#673AB7'},
      'method': {
        'netbanking': true,
        'card': true,
        'upi': true,
        'wallet': false, // Disable wallet payments including Google Pay
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment successful: ${response.paymentId}")),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
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
                    price: '₹ 199.00',
                    label: 'Monthly',
                    isSelected: selectedPlan == 'Monthly',
                    onTap: () {
                      setState(() {
                        selectedPlan = 'Monthly';
                        selectedAmount = 199;
                      });
                    },
                  ),
                  buildPriceCard(
                    price: '₹ 599.00',
                    label: 'Annually',
                    isSelected: selectedPlan == 'Annually',
                    onTap: () {
                      setState(() {
                        selectedPlan = 'Annually';
                        selectedAmount = 599;
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
                    if (selectedAmount > 0 && selectedPlan.isNotEmpty) {
                      _startPayment(selectedAmount, selectedPlan);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a plan.')),
                      );
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
