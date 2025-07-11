import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dart:async';
import 'package:shiftly/db/database_helper.dart';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _backupTimer;

  @override
  void initState() {
    super.initState();
    _createBackupDirectory();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      // Start periodic backup timer after navigation
      _startBackupTimer();
    });
  }

  void _createBackupDirectory() async {
    final backupDir = Directory('/storage/emulated/0/Documents/Shiftly');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      print('Backup directory created at ${backupDir.path}');
    } else {
      print('Backup directory already exists at ${backupDir.path}');
    }
  }

  void _startBackupTimer() {
    final dbHelper = DatabaseHelper();
    print('Starting backup timer...');
    // Backup every 2 hours (7200 seconds)
    _backupTimer = Timer.periodic(Duration(hours: 2), (timer) async {
      print('Backup timer tick...');
      try {
        bool success = await dbHelper.backupDatabase();
        if (success) {
          print('Automatic database backup completed.');
          print('Backup stored at /storage/emulated/0/Documents/Shiftly');
        } else {
          print('Automatic database backup failed.');
        }
      } catch (e) {
        print('Error during automatic backup: $e');
      }
    });
  }

  @override
  void dispose() {
    _backupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            // const Text(
            //   'Shiftly',
            //   style: TextStyle(
            //     fontSize: 32,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.black, // Black text for contrast
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
