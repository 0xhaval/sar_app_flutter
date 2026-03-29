import 'package:flutter/material.dart';
import '../widgets/staggered_column.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.call('get_profile');
      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = (_profile['display_name'] ?? _profile['employee_name'] ?? '...').toString();
    final String designation = (_profile['designation'] ?? '').toString();
    final String employeeId = (_profile['employee_id'] ?? '').toString();

    final infoItems = [
      {'icon': Icons.email_outlined, 'label': 'البريد الإلكتروني', 'value': (_profile['display_email'] ?? _profile['company_email'] ?? _profile['personal_email'] ?? _profile['user_email'] ?? '').toString()},
      {'icon': Icons.phone_outlined, 'label': 'الهاتف', 'value': (_profile['display_phone'] ?? _profile['cell_phone'] ?? _profile['user_mobile_no'] ?? _profile['user_phone'] ?? '').toString()},
      {'icon': Icons.work_outline, 'label': 'القسم', 'value': (_profile['department'] ?? '').toString()},
      {'icon': Icons.work_outline, 'label': 'المسمى الوظيفي', 'value': designation},
      {'icon': Icons.calendar_today_outlined, 'label': 'تاريخ الانضمام', 'value': (_profile['date_of_joining'] ?? '').toString()},
      {'icon': Icons.business_outlined, 'label': 'الشركة', 'value': (_profile['company'] ?? '').toString()},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Color(0xFF284A63), Color(0xFF3B6E71)]),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/logo.png', height: 28, color: Colors.white),
                const SizedBox(height: 12),
                const Text('الملف الشخصي', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Profile Card
          Transform.translate(
            offset: const Offset(0, -64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(64), child: Center(child: CircularProgressIndicator()))
                  : StaggeredColumn(
                      children: [
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: const Color(0xFF284A63),
                                  child: Text(
                                    name.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join(''),
                                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(designation, style: const TextStyle(fontSize: 14, color: Color(0xFF353535))),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFD9DAD9), borderRadius: BorderRadius.circular(20)),
                                  child: Text(employeeId, style: const TextStyle(fontSize: 14, color: Color(0xFF3B6E71))),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info Card
                        Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: infoItems.where((item) => (item['value'] as String).isNotEmpty).toList().asMap().entries.map((entry) {
                                final item = entry.value;
                                final filteredItems = infoItems.where((i) => (i['value'] as String).isNotEmpty).toList();
                                final isLast = entry.key == filteredItems.length - 1;
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                                  child: Row(children: [
                                    Icon(item['icon'] as IconData, size: 20, color: const Color(0xFF9CA3AF)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['label'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF353535))),
                                          const SizedBox(height: 2),
                                          Text(item['value'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ]),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _handleLogout,
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
