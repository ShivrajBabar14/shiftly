import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dart:async';
import 'package:shiftly/db/database_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

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
    final dbPath = await getDatabasesPath();
    final backupDir = Directory(path.join(dbPath, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      print('Backup directory created at ${backupDir.path}');
    } else {
      print('Backup directory already exists at ${backupDir.path}');
    }
  }

  void _startBackupTimer() {
    final dbHelper = DatabaseHelper();
    // Backup every 2 hours (7200 seconds)
    _backupTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await dbHelper.backupDatabase();
      print('Automatic database backup completed.');
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
