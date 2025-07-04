import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'add_employee_screen.dart'; // Import your AddEmployeeScreen here

class AppDrawer extends StatelessWidget {
  static const platform = MethodChannel('com.example.employeeshifttracker/mail');

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
        } else if (title == 'Write Feedback') {
          _launchFeedbackMail(context);
        } else if (title == 'Rate Us') {
          _launchRateUs(context);
        } else if (title == 'Share App') {
          _shareApp(context);
        }
      },
    );
  }

  Future<void> _launchFeedbackMail(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('openGmail', {
          'to': 'linearapps.in@gmail.com',
          'subject': 'Feedback on the App',
          'body': 'Please provide your feedback here...',
        });
        return;
      }

      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'linearapps.in@gmail.com',
        queryParameters: {
          'subject': 'Feedback on the App',
          'body': 'Please provide your feedback here...',
        },
      );

      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No mail app found on this device. Please install a mail app to send feedback.')),
      );
    } on PlatformException catch (e) {
      print("Failed to open Gmail app: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open Gmail app.')),
      );
    }
  }

  Future<void> _launchRateUs(BuildContext context) async {
    final String packageName =
        'com.example.employeeshifttracker'; // Replace with your actual package name
    final Uri playStoreUri = Uri.parse('market://details?id=$packageName');
    final Uri playStoreWebUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    try {
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri);
      } else if (await canLaunchUrl(playStoreWebUri)) {
        await launchUrl(playStoreWebUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Play Store app not found on this device.')),
        );
      }
    } catch (e) {
      print("Failed to open Play Store: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open Play Store.')));
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    final String appLink =
        'https://play.google.com/store/apps/details?id=com.example.employeeshifttracker'; // Replace with your app link

    try {
      await Share.share('Check out this app: $appLink');
    } catch (e) {
      print("Error while sharing: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share the app.')));
    }
  }

  // Widget _buildDrawerItem(IconData icon, String title, BuildContext context) {
  //   return ListTile(
  //     leading: Icon(icon, color: Colors.deepPurple),
  //     title: Text(title, style: TextStyle(color: Colors.black87)),
  //     onTap: () {
  //       if (title == 'All Employees') {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => AddEmployeeScreen()),
  //         );
  //       } else if (title == 'Write Feedback') {
  //         _launchFeedbackMail(context);
  //       } else if (title == 'Rate Us') {
  //         _launchRateUs(context);
  //       } else if (title == 'Share App') {
  //         _shareApp(context);
  //       }
  //     },
  //   );
  // }
}
