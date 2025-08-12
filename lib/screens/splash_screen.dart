import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'subscription.dart';
import 'dart:async';
import '../services/go_pro_display_service.dart';
import 'package:Shiftwise/services/subscription_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure navigation happens safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToHome();
    });
  }

  void _navigateToHome() async {
    // First, refresh subscription status to ensure we have the latest data
    await SubscriptionService().refreshSubscriptionStatus();
    await SubscriptionService().loadSubscriptionStatus();
    
    // Check if user is subscribed
    final isSubscribed = SubscriptionService().isSubscribed;
    
    // Use a short delay to ensure splash screen is visible
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (!isSubscribed) {
          // Check if Go Pro page should be shown for free users
          GoProDisplayService.shouldShowGoProPage().then((shouldShowGoPro) {
            if (shouldShowGoPro) {
              // Record that Go Pro page is being shown
              GoProDisplayService.recordGoProShown();
              
              // Navigate to Go Pro page for free users
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ShiftlyProScreen()),
              );
            } else {
              // Navigate to Home for free users (not time to show Go Pro)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            }
          });
        } else {
          // Subscribed users go directly to Home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Image.asset(
                'assets/app_logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
