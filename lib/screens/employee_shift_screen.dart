// import 'dart:typed_data';
// import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Shiftwise/db/database_helper.dart';
import 'package:Shiftwise/models/employee.dart';
// import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:image/image.dart' as img;

class EmployeeShiftScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeShiftScreen({Key? key, required this.employee})
    : super(key: key);

  @override
  State<EmployeeShiftScreen> createState() => _EmployeeShiftScreenState();
}

class _EmployeeShiftScreenState extends State<EmployeeShiftScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late DateTime _currentWeekStart;
  late DateTime _currentWeekEnd;
  bool _isLoading = true;
  List<Map<String, dynamic>> _shiftData = [];

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _dbHelper.getStartOfWeek(DateTime.now());
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
    _loadShiftData();
  }

  void _loadShiftData() async {
    setState(() {
      _isLoading = true;
    });
    final weekStartMillis = _currentWeekStart.millisecondsSinceEpoch;
    final data = await _dbHelper.getShiftsForEmployeeWeek(
      widget.employee.employeeId!,
      weekStartMillis,
    );
    setState(() {
      _shiftData = data;
      _isLoading = false;
    });
  }

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
      _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
    });
    _loadShiftData();
  }

  String _formatDateRange() {
    final start = DateFormat('MMM d').format(_currentWeekStart);
    final end = DateFormat('MMM d').format(_currentWeekEnd);
    return '$start - $end';
  }

  String _formatShiftTime(Map<String, dynamic> shift) {
    final shiftName = shift['shift_name'] ?? '';
    final startTimeMillis = shift['start_time'];
    final endTimeMillis = shift['end_time'];

    String formatTime(int? millis) {
      if (millis == null) return '';
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final startTime = formatTime(startTimeMillis);
    final endTime = formatTime(endTimeMillis);

    if (shiftName.isNotEmpty && startTime.isNotEmpty && endTime.isNotEmpty) {
      return '$shiftName ($startTime to $endTime)';
    } else if (shiftName.isNotEmpty) {
      return shiftName;
    } else if (startTime.isNotEmpty && endTime.isNotEmpty) {
      return '$startTime to $endTime';
    } else {
      return '';
    }
  }

  String _dayLabel(int index) {
    final date = _currentWeekStart.add(Duration(days: index));
    return DateFormat('EEEE').format(date);
  }

  String _dateLabel(int index) {
    final date = _currentWeekStart.add(Duration(days: index));
    return DateFormat('d').format(date);
  }

  Map<String, dynamic>? _getShiftForDay(String day) {
    // Map full day name to database day key
    final dayMap = {
      'Monday': 'mon',
      'Tuesday': 'tue',
      'Wednesday': 'wed',
      'Thursday': 'thu',
      'Friday': 'fri',
      'Saturday': 'sat',
      'Sunday': 'sun',
    };
    final dbDay = dayMap[day] ?? day.toLowerCase();

    try {
      return _shiftData.firstWhere((shift) => shift['day'] == dbDay);
    } catch (e) {
      return null;
    }
  }

  Future<void> _shareImage() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/shift.png').writeAsBytes(image);

    final dateRange = _formatDateRange();

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Employee Shift for $dateRange');
  }

  Future<void> _sharePDF() async {
    final pdf = pw.Document();

    final image = await _screenshotController.capture();
    if (image == null) return;

    final pdfImage = pw.MemoryImage(image);

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              // pw.Text(
              //   widget.employee.name,
              //   style: pw.TextStyle(
              //     fontSize: 24,
              //     fontWeight: pw.FontWeight.bold,
              //   ),
              // ),
              pw.SizedBox(height: 10),
              pw.Expanded(child: pw.Center(child: pw.Image(pdfImage))),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'shift.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.deepPurple),
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.end, // Aligns the content to the right
          children: [
            //  Expanded(
            //   child: Text(
            //     widget.employee.name,
            //     style: const TextStyle(
            //       color: Colors.deepPurple,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            // Right-aligned share icon
            PopupMenuButton<String>(
              color: Colors.white,
              icon: const Icon(Icons.share, color: Colors.deepPurple),
              onSelected: (value) async {
                if (value == 'image') {
                  await _shareImage();
                } else if (value == 'pdf') {
                  await _sharePDF();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'image',
                    child: Row(
                      children: const [
                        Icon(Icons.image, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text('Share Image'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'pdf',
                    child: Row(
                      children: const [
                        Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text('Share PDF'),
                      ],
                    ),
                  ),
                ];
              },
              offset: const Offset(0, 40), // Adjust the pop-up position
              elevation: 4,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Employee name inside Screenshot widget
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              widget.employee.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  onPressed: () => _changeWeek(-7),
                                ),
                                Text(
                                  _formatDateRange(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  onPressed: () => _changeWeek(7),
                                ),
                              ],
                            ),
                          ),
                          Table(
                            border: TableBorder.all(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(1.5),
                            },
                            children: [
                              // Table header
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Date',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Shift',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Table rows for each day
                              ...List.generate(7, (index) {
                                final dayName = _dayLabel(index);
                                final dateNumber = _dateLabel(index);
                                final shift = _getShiftForDay(dayName);
                                final shiftText = shift != null
                                    ? _formatShiftTime(shift)
                                    : 'No Shift';

                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey.shade50,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            dateNumber,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            dayName,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 70.0,
                                      alignment: Alignment.center,
                                      child: Builder(
                                        builder: (context) {
                                          final shiftName =
                                              shift?['shift_name'] ?? '';
                                          final startTimeMillis =
                                              shift?['start_time'];
                                          final endTimeMillis =
                                              shift?['end_time'];

                                          String formatTime(int? millis) {
                                            if (millis == null) return '';
                                            final dt =
                                                DateTime.fromMillisecondsSinceEpoch(
                                                  millis,
                                                );
                                            return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                          }

                                          final startTime = formatTime(
                                            startTimeMillis,
                                          );
                                          final endTime = formatTime(
                                            endTimeMillis,
                                          );

                                          final hasName = shiftName.isNotEmpty;
                                          final hasTime =
                                              startTime.isNotEmpty &&
                                              endTime.isNotEmpty;

                                          if (hasName && hasTime) {
                                            return RichText(
                                              textAlign: TextAlign.center,
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: shiftName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '\n($startTime to $endTime)',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontSize: 16,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else if (hasName) {
                                            return Text(
                                              shiftName,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            );
                                          } else if (hasTime) {
                                            return Text(
                                              '$startTime to $endTime',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            );
                                          } else {
                                            return const Text(
                                              '',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black54,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
