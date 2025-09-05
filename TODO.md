# Task: Disable mark attendance fields and radio buttons for future days in _showShiftDialog

- [x] Edit lib/screens/home_screen.dart to modify the "Mark Attendance" section in _showShiftDialog method
  - Disable the RadioListTile onChanged callbacks for future days by setting them to null when isFutureDay is true
- [ ] Verify the changes work as expected (attendance fields disabled for future days, enabled for past/current days)
