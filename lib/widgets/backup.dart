import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:Shiftwise/db/database_helper.dart';
import 'package:Shiftwise/services/backup_refresh_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:Shiftwise/screens/home_screen.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

void showBackupRestoreDialog(
  BuildContext context,
  String initialDirectory, {
  DateTime? lastBackupDate,
  VoidCallback? onRestoreSuccess,
}) {
  showDialog(
    context: context,
    builder: (context) {
      final lastBackupStr = lastBackupDate != null
          ? DateFormat('dd MMM yyyy HH:mm').format(lastBackupDate)
          : 'No backup found';

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Backup & Restore',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Backup Path',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(initialDirectory, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 20),
              // Text(
              //   'Last Backup',
              //   style: TextStyle(fontWeight: FontWeight.w600),
              // ),
              // const SizedBox(height: 4),
              // Text(lastBackupStr, style: TextStyle(color: Colors.black87)),
              // const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final dbHelper = DatabaseHelper();
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                        initialDirectory: initialDirectory,
                      );
                      if (result == null || result.files.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No file selected.')),
                          );
                        }

                        // 📊 Log event for no file selection
                        await analytics.logEvent(
                          name: 'restore_data_attempt',
                          parameters: {'status': 'no_file_selected'},
                        );
                        return;
                      }
                      final filePath = result.files.single.path;
                      if (filePath == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid file path.')),
                          );
                        }

                        // 📊 Log event for invalid file path
                        await analytics.logEvent(
                          name: 'restore_data_attempt',
                          parameters: {'status': 'invalid_file_path'},
                        );

                        return;
                      }
                      final success = await dbHelper.restoreFromFile(filePath);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Backup restored successfully.'),
                            ),
                          );

                          // Trigger automatic refresh logic if needed
                          await BackupRefreshService().refreshAfterRestore();

                          // Call HomeScreen's refresh if provided
                          if (onRestoreSuccess != null) {
                            onRestoreSuccess!();
                          }
                          // 📊 Log successful restore
                          await analytics.logEvent(
                            name: 'restore_data_attempt',
                            parameters: {
                              'status': 'success',
                              'file_path': filePath,
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to restore backup.'),
                            ),
                          );
                          // 📊 Log failed restore
                          await analytics.logEvent(
                            name: 'restore_data_attempt',
                            parameters: {
                              'status': 'failed',
                              'file_path': filePath,
                            },
                          );
                        }
                      }
                    } catch (e) {
                      // if (context.mounted) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     SnackBar(content: Text('Error selecting file: $e')),
                      //   );
                      // }
                    }
                    Navigator.pop(
                      context,
                    ); // Close dialog after showing SnackBar
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Restore Data',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
