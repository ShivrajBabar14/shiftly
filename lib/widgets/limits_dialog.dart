import 'package:flutter/material.dart';

class LimitsDialog extends StatelessWidget {
  final VoidCallback onGoPro;
  final VoidCallback onContinueFree;

  const LimitsDialog({
    Key? key,
    required this.onGoPro,
    required this.onContinueFree,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock premium features with Shiftwise Pro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: Colors.deepPurple, // Deep purple heading
              ),
            ),
            const SizedBox(height: 20),
            _buildFeatureItem('Add unlimited employees'),
            _buildFeatureItem('Enable auto backups'),
            _buildFeatureItem('Access advanced shift scheduling'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onContinueFree,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text(
                    'Continue Free',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold, // Bold text
                      color: Colors.black, // Black color
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: onGoPro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple, // Deep purple button
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Go Pro',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.circle, size: 6, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}