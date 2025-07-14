import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'add_employee_screen.dart';
import 'package:shiftly/db/database_helper.dart';
import 'subscription.dart';
// import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:permission_handler/permission_handler.dart';

class AppDrawer extends StatelessWidget {
  static const platform = MethodChannel(
    'com.example.employeeshifttracker/mail',
  );

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
                      'assets/app_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                _buildDrawerItem(Icons.group, 'All Employees', context),
                _buildDrawerItem(Icons.upgrade, 'Subscription', context),
                _buildDrawerItem(Icons.share, 'Share App', context),
                _buildDrawerItem(Icons.star, 'Rate Us', context),
                _buildDrawerItem(Icons.feedback, 'Write Feedback', context),
                ListTile(
                  leading: Icon(Icons.restore, color: Colors.deepPurple),
                  title: Text(
                    'Restore Data',
                    style: TextStyle(color: Colors.black87),
                  ),
                  onTap: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    Navigator.of(context).pop();
                    final dbHelper = DatabaseHelper();

                    // Request storage permission
                    bool permissionGranted = await dbHelper.checkStoragePermissions();
                    if (!permissionGranted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Storage permission denied.')),
                      );
                      return;
                    }

                    // Open file picker to select backup file
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                        initialDirectory: '/storage/emulated/0/',
                      );

                      if (result == null || result.files.isEmpty) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('No file selected.')),
                        );
                        return;
                      }

                      final filePath = result.files.single.path;
                      if (filePath == null) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Invalid file path.')),
                        );
                        return;
                      }

                      bool restoreSuccess = await dbHelper.restoreFromFile(filePath);
                      if (restoreSuccess) {
                        bool backupSuccess = false;
                        try {
                          await dbHelper.backupDatabase();
                          backupSuccess = true;
                        } catch (e) {
                          backupSuccess = false;
                        }
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Database restored from selected file. ' +
                                  (backupSuccess
                                      ? 'Backup created successfully.'
                                      : 'Backup creation failed.'),
                            ),
                          ),
                        );
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Failed to restore from selected file.')),
                        );
                      }
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error selecting file: $e')),
                      );
                    }
                  },
                ),
                // ListTile(
                //   leading: Icon(Icons.file_download, color: Colors.deepPurple),
                //   title: Text(
                //     'Export Data',
                //     style: TextStyle(color: Colors.black87),
                //   ),
                //   onTap: () async {
                //     Navigator.of(context).pop();
                //     await _exportData(context);
                //   },
                // ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Version (4.13)',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(color: Colors.black87)),
      onTap: () {
        Navigator.of(context).pop(); // Close the drawer

        if (title == 'All Employees') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEmployeeScreen()),
          );
        } else if (title == 'Subscription') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ShiftlyProScreen()),
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
        SnackBar(
          content: Text(
            'No mail app found on this device. Please install a mail app to send feedback.',
          ),
        ),
      );
    } on PlatformException catch (e) {
      print("Failed to open Gmail app: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open Gmail app.')));
    }
  }

  Future<void> _launchRateUs(BuildContext context) async {
    final String packageName = 'com.example.employeeshifttracker';
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
        'https://play.google.com/store/apps/details?id=com.example.employeeshifttracker';

    try {
      await Share.share('Check out this app: $appLink');
    } catch (e) {
      print("Error while sharing: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share the app.')));
    }
  }

  // Future<void> _exportData(BuildContext context) async {
  //   PermissionStatus status = await Permission.storage.request();
  //   if (!status.isGranted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Storage permission denied')));
  //     return;
  //   }

  //   try {
  //     final dbHelper = DatabaseHelper();
  //     final employees = await dbHelper.getEmployees();

  //     var excel = Excel.createExcel();
  //     var sheetObject = excel['Employees'];

  //     // Add header row (no need for CellValue.string(), just direct values)
  //     sheetObject.appendRow([
  //       'Employee ID',
  //       'Name',
  //       // Add other columns as needed
  //     ]);

  //     // Add data rows (direct values)
  //     for (var emp in employees) {
  //       sheetObject.appendRow([
  //         emp['employee_id'].toString(),
  //         emp['name'].toString(),
  //         // Add other fields as needed
  //       ]);
  //     }

  //     // Get directory and save file
  //     final directory = await getExternalStorageDirectory();
  //     if (directory == null) {
  //       throw Exception('Could not access storage directory');
  //     }

  //     final filePath = path.join(directory.path, 'employees_export.xlsx');
  //     final fileBytes = excel.encode();

  //     if (fileBytes == null) {
  //       throw Exception('Failed to encode Excel file');
  //     }

  //     final file = File(filePath);
  //     await file.writeAsBytes(fileBytes);

  //     if (await file.exists()) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Data exported successfully to $filePath'),
  //           action: SnackBarAction(
  //             label: 'Open',
  //             onPressed: () async {
  //               if (await canLaunchUrl(Uri.file(filePath))) {
  //                 await launchUrl(Uri.file(filePath));
  //               }
  //             },
  //           ),
  //         ),
  //       );
  //     } else {
  //       throw Exception('File not found after export');
  //     }
  //   } catch (e) {
  //     print('Export error: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to export data: ${e.toString()}')),
  //     );
  //   }
  // }
}
