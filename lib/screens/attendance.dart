import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../widgets/calendar_view.dart';
import '../widgets/animated_bottom_sheet.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  bool _checkedIn = false;
  String? _checkInTime;
  late TabController _tabController;

  final List<AttendanceRecord> _attendanceData = [
    AttendanceRecord(date: '2026-03-19', checkIn: '9:00 ص', checkOut: '6:00 م', hours: 9, status: 'present'),
    AttendanceRecord(date: '2026-03-18', checkIn: '9:15 ص', checkOut: '6:10 م', hours: 8.92, status: 'present'),
    AttendanceRecord(date: '2026-03-17', checkIn: '9:05 ص', checkOut: '6:05 م', hours: 9, status: 'present'),
    AttendanceRecord(date: '2026-03-15', hours: 0, status: 'leave'),
    AttendanceRecord(date: '2026-03-14', checkIn: '9:10 ص', checkOut: '6:15 م', hours: 9.08, status: 'present'),
    AttendanceRecord(date: '2026-03-13', checkIn: '9:20 ص', checkOut: '2:00 م', hours: 4.67, status: 'half-day'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCurrentTime() {
    return DateFormat('hh:mm a', 'ar').format(DateTime.now());
  }

  void _handleCheckIn() {
    final time = _getCurrentTime();
    setState(() {
      _checkedIn = true;
      _checkInTime = time;
    });
    Fluttertoast.showToast(msg: 'تم تسجيل الحضور في $time');
  }

  void _handleCheckOut() {
    final time = _getCurrentTime();
    setState(() {
      _checkedIn = false;
    });
    Fluttertoast.showToast(msg: 'تم تسجيل الانصراف في $time');
  }

  void _showAttendanceRequestDialog() {
    String? selectedType;
    final dateController = TextEditingController();
    final checkInController = TextEditingController();
    final checkOutController = TextEditingController();
    final reasonController = TextEditingController();

    showAnimatedBottomSheet(
      context: context,
      title: 'طلب تسوية الحضور',
      subtitle: 'قدم طلب لتسوية سجل الحضور الخاص بك',
      children: [
        StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نوع الطلب', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    hintText: 'اختر النوع',
                  ),
                  items: [
                    'نسيان تسجيل الحضور',
                    'نسيان تسجيل الانصراف',
                    'وقت خاطئ',
                    'خطأ في النظام',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setSheetState(() => selectedType = v),
                ),
                const SizedBox(height: 16),
                const Text('التاريخ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'اختر التاريخ',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: const Locale('ar'),
                    );
                    if (date != null) {
                      dateController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وقت الحضور', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: checkInController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'اختر الوقت',
                              suffixIcon: Icon(Icons.access_time, size: 18),
                            ),
                            onTap: () async {
                              final ctx = context;
                              final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                              if (time != null && ctx.mounted) {
                                checkInController.text = time.format(ctx);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وقت الانصراف', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: checkOutController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'اختر الوقت',
                              suffixIcon: Icon(Icons.access_time, size: 18),
                            ),
                            onTap: () async {
                              final ctx = context;
                              final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                              if (time != null && ctx.mounted) {
                                checkOutController.text = time.format(ctx);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('السبب', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'اشرح سبب طلبك...',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Fluttertoast.showToast(msg: 'تم تقديم طلب تسوية الحضور بنجاح!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('تقديم الطلب', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present': return 'حاضر';
      case 'half-day': return 'نصف يوم';
      case 'leave': return 'إجازة';
      default: return 'غائب';
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'present': return const Color(0xFFDCFCE7);
      case 'half-day': return const Color(0xFFFEF9C3);
      case 'leave': return const Color(0xFFDBEAFE);
      default: return const Color(0xFFFEE2E2);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'present': return const Color(0xFF15803D);
      case 'half-day': return const Color(0xFFA16207);
      case 'leave': return const Color(0xFF1D4ED8);
      default: return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentTime = DateFormat('hh:mm', 'ar').format(now);
    final currentDate = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF9333EA), Color(0xFF2563EB)],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الحضور والانصراف', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),

                // Clock Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Time Display
                      Text(currentTime, style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(currentDate, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 24),

                      // Check-in/out Buttons with AnimatedSwitcher
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 96,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: FadeTransition(opacity: animation, child: child),
                                  );
                                },
                                child: _checkedIn
                                    ? ElevatedButton(
                                        key: const ValueKey('checkout'),
                                        onPressed: _handleCheckOut,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          minimumSize: const Size(double.infinity, 96),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.logout, size: 32),
                                            SizedBox(height: 8),
                                            Text('تسجيل الانصراف'),
                                          ],
                                        ),
                                      )
                                    : ElevatedButton(
                                        key: const ValueKey('checkin'),
                                        onPressed: _handleCheckIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF22C55E),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          minimumSize: const Size(double.infinity, 96),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login, size: 32),
                                            SizedBox(height: 8),
                                            Text('تسجيل الحضور'),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 96,
                              child: OutlinedButton(
                                onPressed: _showAttendanceRequestDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 32),
                                    SizedBox(height: 8),
                                    Text('طلب تسوية'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Today Stats
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'وقت الحضور: ${_checkedIn ? _checkInTime : 'لم يتم التسجيل'}',
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text('الموقع: بغداد', style: TextStyle(fontSize: 14, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'عرض التقويم'),
                      Tab(text: 'السجل'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      CalendarView(attendanceData: _attendanceData),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _attendanceData.length,
      itemBuilder: (context, index) {
        final record = _attendanceData[index];
        final date = DateTime.parse(record.date);
        final formattedDate = DateFormat('EEEE، d MMM', 'ar').format(date);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      if (record.status == 'present' || record.status == 'half-day')
                        Row(
                          children: [
                            const Icon(Icons.login, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(record.checkIn ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                            const SizedBox(width: 16),
                            const Icon(Icons.logout, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(record.checkOut ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                          ],
                        )
                      else
                        const Text('لا يوجد حضور', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(record.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(record.status),
                        style: TextStyle(fontSize: 12, color: _getStatusTextColor(record.status)),
                      ),
                    ),
                    if (record.hours > 0) ...[
                      const SizedBox(height: 4),
                      Text('${record.hours.toStringAsFixed(1)} ساعة', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
