import 'package:flutter/material.dart';
// import 'package:share_plus/share_plus.dart'; // Import for sharing
// import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs
import 'add_employee_screen.dart'; // Import your AddEmployeeScreen here

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade700,
                        Colors.deepPurple.shade400,
                        Colors.purple.shade300,
                      ],
                      stops: [0.1, 0.6, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/shift.png', // Ensure this image path is correct
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Drawer items with correct context argument passed
                _buildDrawerItem(Icons.group, 'All Employees', context),
                _buildDrawerItem(Icons.share, 'Share App', context),
                _buildDrawerItem(Icons.star, 'Rate Us', context),
                _buildDrawerItem(Icons.feedback, 'Write Feedback', context),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft, // Aligns the text to the left
              child: Text(
                'Version (4.13)', // This is your version text
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This method now expects 3 arguments: icon, title, and context
  Widget _buildDrawerItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(color: Colors.black87)),
      onTap: () {
        if (title == 'All Employees') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEmployeeScreen()),
          );
        // } else if (title == 'Share App') {
        //   _shareApp();
        // } else if (title == 'Rate Us') {
        //   _rateUs();
        // } else if (title == 'Write Feedback') {
        //   _writeFeedback();
        }
      },
    );
  }

  // Method to share the app link
  // void _shareApp() async {
  //   // Replace this with your app's package name or share URL
  //   final String appLink = 'https://play.google.com/store/apps/details?id=com.example.yourapp';

  //   try {
  //     // Share app link
  //     await Share.share('Check out this app: $appLink');
  //   } catch (e) {
  //     print("Error while sharing: $e");
  //   }
  // }

  // Method to rate the app in the Play Store
  // void _rateUs() async {
  //   final String packageName = 'com.example.employeeshifttracker'; 
  //   final String playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';

  //   try {
  //     // Open the Play Store link to rate the app
  //     if (await canLaunch(playStoreUrl)) {
  //       await launch(playStoreUrl);
  //     } else {
  //       throw 'Could not open Play Store';
  //     }
  //   } catch (e) {
  //     print("Error opening Play Store: $e");
  //   }
  // }

  // Method to open mail app with predefined recipient email
  // void _writeFeedback() async {
  //   final String feedbackEmail = 'linearapps.in@gmail.com'; 
  //   final String subject = Uri.encodeComponent('Feedback on the App');
  //   final String body = Uri.encodeComponent('Please provide your feedback here...');
  //   final String mailUrl = 'mailto:$feedbackEmail?subject=$subject&body=$body';

  //   try {
  //     // Open the mail app to send feedback
  //     if (await canLaunch(mailUrl)) {
  //       await launch(mailUrl);
  //     } else {
  //       throw 'Could not open mail app';
  //     }
  //   } catch (e) {
  //     print("Error opening mail app: $e");
  //   }
  // }
}
