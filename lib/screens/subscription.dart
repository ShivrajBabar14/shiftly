import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShiftlyProScreen extends StatelessWidget {
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
              const SizedBox(height: 30),

              // Feature list
              buildFeature(
                assetPath: 'assets/users.png',
                title: 'Unlimited Employee Access',
                subtitle:
                    'Add more than 5 employees to your team with a paid plan',
              ),
              const SizedBox(height: 20),
              buildFeature(
                assetPath: 'assets/backup.png',
                title: 'Auto Backup',
                subtitle: 'Keep your data safe with automatic backup feature',
              ),
              const SizedBox(height: 20),
              buildFeature(
                assetPath: 'assets/schedule.png',
                title: 'Unlimited Employee Access',
                subtitle:
                    'Add more than 5 employees to your team with a paid plan',
              ),

              const SizedBox(height: 40),

              // Pricing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildPriceCard(price: '₹ 199.00', label: 'Monthly'),
                  buildPriceCard(price: '₹ 599.00', label: 'Annually'),
                ],
              ),

              const Spacer(),

              // Go Pro button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Add your payment logic here
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

  // Feature tile widget
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
            color: Colors.deepPurple, // apply tint if icons are monochrome
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
                  color: Color(0xFF424242)
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.questrial(
                  fontSize: 14,
                  color: Color(0xFF616161)
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Price card widget
  Widget buildPriceCard({required String price, required String label}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            price,
            style: GoogleFonts.questrial(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.questrial(fontSize: 14, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }
}
