import 'package:flutter/material.dart';
import '../widgets/staggered_column.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const userInfo = {
      'name': 'أحمد محمد',
      'employeeId': 'EMP001',
      'email': 'ahmed.mohamed@company.com',
      'phone': '+964 770 123 4567',
      'department': 'الهندسة',
      'designation': 'مهندس برمجيات أول',
      'joiningDate': '15 يناير 2023',
      'location': 'مكتب بغداد',
    };

    final infoItems = [
      {'icon': Icons.email_outlined, 'label': 'البريد الإلكتروني', 'value': userInfo['email']!},
      {'icon': Icons.phone_outlined, 'label': 'الهاتف', 'value': userInfo['phone']!},
      {'icon': Icons.work_outline, 'label': 'القسم', 'value': userInfo['department']!},
      {'icon': Icons.work_outline, 'label': 'المسمى الوظيفي', 'value': userInfo['designation']!},
      {'icon': Icons.calendar_today_outlined, 'label': 'تاريخ الانضمام', 'value': userInfo['joiningDate']!},
      {'icon': Icons.location_on_outlined, 'label': 'الموقع', 'value': userInfo['location']!},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: const Text('الملف الشخصي', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
          ),

          // Profile Card (overlapping)
          Transform.translate(
            offset: const Offset(0, -64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StaggeredColumn(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFF2563EB),
                            child: Text(
                              userInfo['name']!.split(' ').map((n) => n[0]).join(''),
                              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(userInfo['name']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(userInfo['designation']!, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              userInfo['employeeId']!,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1D4ED8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Information Card
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: infoItems.asMap().entries.map((entry) {
                          final item = entry.value;
                          final isLast = entry.key == infoItems.length - 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            child: Row(
                              children: [
                                Icon(item['icon'] as IconData, size: 20, color: const Color(0xFF9CA3AF)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['label'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                                      const SizedBox(height: 2),
                                      Text(item['value'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إحصائيات سريعة', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('3.2', style: TextStyle(fontSize: 22, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    const Text('سنوات', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('%95', style: TextStyle(fontSize: 22, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    const Text('معدل الحضور', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('12', style: TextStyle(fontSize: 22, color: Color(0xFF9333EA), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    const Text('إجازات متبقية', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('تسجيل الخروج'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
