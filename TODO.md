# TODO: Update Shift Cell Design for Attendance Status

## Tasks
- [ ] Update shift cell widget in _buildShiftTable method to add attendance square in top right corner
- [ ] Remove current attendance text display below shift info
- [ ] Test the UI changes to verify attendance square appears correctly

## Details
- Add a small colored square (e.g., 20x20) in top right corner of each shift cell
- Square shows letter P (green), A (red), L (yellow) based on attendance status
- Hide square if attendance is 'None' or null
- Replace the existing Text widget for attendance status
