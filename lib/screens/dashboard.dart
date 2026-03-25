import 'package:flutter/material.dart';
import '../widgets/staggered_column.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'icon': Icons.calendar_today, 'label': 'رصيد الإجازات', 'value': '12 يوم', 'color': const Color(0xFF2563EB)},
      {'icon': Icons.access_time, 'label': 'ساعات هذا الشهر', 'value': '168 ساعة', 'color': const Color(0xFF16A34A)},
      {'icon': Icons.assignment_turned_in, 'label': 'الطلبات المعلقة', 'value': '2', 'color': const Color(0xFFEA580C)},
      {'icon': Icons.trending_up, 'label': 'معدل الحضور', 'value': '%95', 'color': const Color(0xFF9333EA)},
    ];

    final recentActivities = [
      {'action': 'تسجيل الحضور', 'time': '9:00 ص', 'date': 'اليوم'},
      {'action': 'الموافقة على الإجازة', 'time': '2:30 م', 'date': 'أمس'},
      {'action': 'تسوية الحضور', 'time': '11:15 ص', 'date': '17 مارس'},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بعودتك،',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'أحمد محمد',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'رقم الموظف: EMP001',
                  style: TextStyle(fontSize: 14, color: Color(0xFFBFDBFE)),
                ),
              ],
            ),
          ),

          // Stats Grid with staggered animation
          Padding(
            padding: const EdgeInsets.all(16),
            child: StaggeredColumn(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: stats.map((stat) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.topStart,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(stat['icon'] as IconData, size: 32, color: stat['color'] as Color),
                              const SizedBox(height: 8),
                              Text(
                                stat['value'] as String,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stat['label'] as String,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Recent Activities
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'النشاطات الأخيرة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ...recentActivities.asMap().entries.map((entry) {
                          final activity = entry.value;
                          final isLast = entry.key == recentActivities.length - 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['action']!,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activity['date']!,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                    ),
                                  ],
                                ),
                                Text(
                                  activity['time']!,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
