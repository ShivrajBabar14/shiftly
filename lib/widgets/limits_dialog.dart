import 'package:flutter/material.dart';
import '../utils/strings.dart';

class LimitsDialog extends StatefulWidget {
  final VoidCallback onGoPro;
  final VoidCallback onContinueFree;
  final void Function()? onDialogShown; // <-- Add this optional callback

  const LimitsDialog({
    Key? key,
    required this.onGoPro,
    required this.onContinueFree,
    this.onDialogShown,
  }) : super(key: key);

  @override
  _LimitsDialogState createState() => _LimitsDialogState();
}

class _LimitsDialogState extends State<LimitsDialog> {
  @override
  void initState() {
    super.initState();

    // Fire analytics event when dialog is shown
    widget.onDialogShown?.call();

    // OR directly call your analytics service here:
    // AnalyticsService.logEvent("limit_dialog_shown");
  }

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
              AppStrings.unlockPremiumTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(AppStrings.featureUnlimitedEmployees),
            _buildFeatureItem(AppStrings.featureAutoBackup),
            _buildFeatureItem(AppStrings.featureAdvancedScheduling),
            _buildFeatureItem(AppStrings.featureMarkAttendance),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onContinueFree,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text(
                    AppStrings.continueFreeButton,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.onGoPro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    AppStrings.goProButton,
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
            padding: EdgeInsets.only(top: 6),
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
