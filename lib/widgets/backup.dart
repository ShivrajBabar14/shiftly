import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

void showBackupRestoreDialog(BuildContext context, String initialDirectory, {DateTime? lastBackupDate}) {
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
              Text(
                initialDirectory,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Text(
                'Last Backup',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                lastBackupStr,
                style: TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                        initialDirectory: initialDirectory,
                      );
                      // Handle the selected file path here if needed
                      if (result == null || result.files.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No file selected.')),
                        );
                        return;
                      }
                      final filePath = result.files.single.path;
                      if (filePath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid file path.')),
                        );
                        return;
                      }
                      // You can add logic here to restore from the selected file if needed
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error selecting file: $e')),
                      );
                    }
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
              )
            ],
          ),
        ),
      );
    },
  );
}
