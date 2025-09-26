import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Shiftwise/db/database_helper.dart';
import 'package:Shiftwise/models/employee.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Shiftwise/utils/strings.dart';
import '../generated/l10n.dart';



class EmployeeShiftScreen extends StatefulWidget {
  final Employee employee;
  final DateTime? weekStart;
  final bool isFreeUser; 
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  EmployeeShiftScreen({Key? key, required this.employee, required this.isFreeUser, this.weekStart})
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

  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();

    _currentWeekStart =
        widget.weekStart ?? _dbHelper.getStartOfWeek(DateTime.now());
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));

    _logScreenShownEvent();
    _loadShiftData();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AppStrings.bannerAdUnitID,  // Test Ad Unit
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    );

    _bannerAd.load();
  }

  void _logScreenShownEvent() {
    widget._analytics.logEvent(
      name: 'employee_shift_screen_shown',
      parameters: {
        'employee_id': widget.employee.employeeId,
        'employee_name': widget.employee.name,
      },
    );
  }

  void _loadShiftData() async {
    setState(() {
      _isLoading = true;
    });
    final weekStartMillis = _currentWeekStart.millisecondsSinceEpoch;
    print('DEBUG: Loading shift data for employee ${widget.employee.employeeId} at week start $weekStartMillis');
    final data =
        await _dbHelper.getShiftsForEmployeeWeek(widget.employee.employeeId!, weekStartMillis);
    print('DEBUG: Fetched shift data: $data');

    // If no data, check if employee is assigned to the week and add if not
    if (data.isEmpty) {
      print('DEBUG: No shift data found, checking week assignment');
      final assignments = await _dbHelper.getEmployeesForWeek(weekStartMillis);
      final isAssigned = assignments.any((emp) => emp['employee_id'] == widget.employee.employeeId);
      if (!isAssigned) {
        print('DEBUG: Employee not assigned to week, adding now');
        await _dbHelper.addEmployeeToWeek(widget.employee.employeeId!, weekStartMillis);
        // Reload data after adding
        final newData = await _dbHelper.getShiftsForEmployeeWeek(widget.employee.employeeId!, weekStartMillis);
        print('DEBUG: Reloaded shift data after adding: $newData');
        setState(() {
          _shiftData = newData;
          _isLoading = false;
        });
        return;
      }
    }

    setState(() {
      _shiftData = data;
      _isLoading = false;
    });
    print('DEBUG: _shiftData set to $_shiftData');
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

  String _dayLabel(int index) {
    final date = _currentWeekStart.add(Duration(days: index));
    return DateFormat('EEEE').format(date);
  }

  String _dateLabel(int index) {
    final date = _currentWeekStart.add(Duration(days: index));
    return DateFormat('d').format(date);
  }

  Map<String, dynamic>? _getShiftForDay(String day) {
    final dayMap = {
      S.of(context)!.monday: S.of(context)!.mondayAbbr,
      S.of(context)!.tuesday: S.of(context)!.tuesdayAbbr,
      S.of(context)!.wednesday: S.of(context)!.wednesdayAbbr,
      S.of(context)!.thursday: S.of(context)!.thursdayAbbr,
      S.of(context)!.friday: S.of(context)!.fridayAbbr,
      S.of(context)!.saturday: S.of(context)!.saturdayAbbr,
      S.of(context)!.sunday: S.of(context)!.sundayAbbr,
    };
    final dbDay = dayMap[day] ?? day.toLowerCase();
    print('DEBUG: Looking for day $day mapped to $dbDay in _shiftData');

    try {
      final shift = _shiftData.firstWhere((shift) => shift['day'] == dbDay);
      print('DEBUG: Found shift for $dbDay: $shift');
      return shift;
    } catch (e) {
      print('DEBUG: No shift found for $dbDay');
      return null;
    }
  }

  Future<void> _shareImage() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/${S.of(context)!.shift}.png').writeAsBytes(image);

    final dateRange = _formatDateRange();

    await Share.shareXFiles([XFile(file.path)], text: '${S.of(context)!.shareImgText} $dateRange');
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
              pw.SizedBox(height: 10),
              pw.Expanded(child: pw.Center(child: pw.Image(pdfImage))),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: '${S.of(context)!.shift}.pdf');
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;     // status bar + nav bar
    final viewInsets = MediaQuery.of(context).viewInsets; // keyboard

    return Scaffold(
      resizeToAvoidBottomInset: true, // Let Scaffold handle keyboard automatically
      appBar: AppBar(
        leading: BackButton(color: Colors.deepPurple),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PopupMenuButton<String>(
              color: Colors.white,
              icon: const Icon(Icons.share, color: Colors.deepPurple),
              onSelected: (value) async {
                await widget._analytics.logEvent(
                  name: S.of(context)!.shiftShare,
                  parameters: {
                    'employee_id': widget.employee.employeeId,
                    'employee_name': widget.employee.name,
                    'share_type': value,
                  },
                );

                if (value == S.of(context)!.img) {
                  await _shareImage();
                } else if (value == S.of(context)!.pdf) {
                  await _sharePDF();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: S.of(context)!.img,
                    child: Row(
                      children: [
                        Icon(Icons.image, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(S.of(context)!.shareImg),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: S.of(context)!.pdf,
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(S.of(context)!.sharePdf),
                      ],
                    ),
                  ),
                ];
              },
              offset: const Offset(0, 40),
              elevation: 4,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: padding.left,
          // top: padding.top,
          right: padding.right,
          // bottom: nav bar + keyboard height
          bottom: padding.bottom + viewInsets.bottom,
        ),
        child: _buildMainLayout(),
      ),
    );
  }

  Widget _buildMainLayout() {
    return SafeArea(
      bottom: true,
      child: Stack(
        children: [
          Column(
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
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    onPressed: () => _changeWeek(7),
                                  ),
                                ],
                              ),
                            ),
                            Table(
                              border: TableBorder.all(color: Colors.grey.shade300, width: 1.0),
                              columnWidths: const {
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(1.5),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: Colors.deepPurple),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: Text(
                                          S.of(context)!.date,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: Text(
                                          S.of(context)!.shift,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ...List.generate(7, (index) {
                                  final dayName = _dayLabel(index);
                                  final dateNumber = _dateLabel(index);
                                  final shift = _getShiftForDay(dayName);
                                  print('DEBUG: Day $dayName, shift: $shift');

                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                                            Text(dayName, style: TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 75.0,
                                        alignment: Alignment.center,
                                        child: Builder(
                                          builder: (context) {
                                            final shiftName = shift?['shift_name'] ?? '';
                                            final startTimeMillis = shift?['start_time'];
                                            final endTimeMillis = shift?['end_time'];

                                            String formatTime(int? millis) {
                                              if (millis == null) return '';
                                              final dt = DateTime.fromMillisecondsSinceEpoch(millis);
                                              return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                            }

                                            final startTime = formatTime(startTimeMillis);
                                            final endTime = formatTime(endTimeMillis);

                                            final hasName = shiftName.isNotEmpty;
                                            final hasTime = startTime.isNotEmpty && endTime.isNotEmpty;

                                            if (hasName || hasTime) {
                                              return Align(
                                                alignment: Alignment.center,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    borderRadius: BorderRadius.circular(4.0),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      hasName && hasTime
                                                          ? RichText(
                                                              textAlign: TextAlign.center,
                                                              text: TextSpan(
                                                                children: [
                                                                  TextSpan(
                                                                    text: shiftName,
                                                                    style: const TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 16,
                                                                      color: Colors.black,
                                                                    ),
                                                                  ),
                                                                  TextSpan(
                                                                    text: '\n($startTime to $endTime)',
                                                                    style: const TextStyle(
                                                                      fontWeight: FontWeight.normal,
                                                                      fontSize: 16,
                                                                      color: Colors.black,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : hasName || hasTime
                                                              ? RichText(
                                                                  textAlign: TextAlign.center,
                                                                  text: TextSpan(
                                                                    children: [
                                                                      TextSpan(
                                                                        text: hasName ? shiftName : '$startTime to $endTime',
                                                                        style: const TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 16,
                                                                          color: Colors.black,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                              : SizedBox.shrink(),
                                                      if (shift?['status'] != null && shift?['status'] != 'None')
                                                        Container(
                                                          margin: const EdgeInsets.only(top: 8.0),
                                                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                                          decoration: BoxDecoration(
                                                            color: shift!['status'] == S.of(context)!.present
                                                                ? Colors.green
                                                                : shift!['status'] == S.of(context)!.absent
                                                                    ? Colors.red
                                                                    : Colors.yellow[700],
                                                            borderRadius: BorderRadius.circular(4.0),
                                                          ),
                                                          child: Text(
                                                            shift!['status'],
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Align(
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.add,
                                                  size: 16.0,
                                                  color: Colors.grey[300],
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
              // Banner Ad at the bottom
              if (widget.isFreeUser && _isBannerAdLoaded)
                Container(
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
