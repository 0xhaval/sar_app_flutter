import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'theme/brand.dart';
import 'screens/dashboard.dart';
import 'screens/leaves.dart';
import 'screens/attendance.dart';
import 'screens/apartments.dart';
import 'screens/inventory.dart';
import 'screens/customers.dart';
import 'screens/profile.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LeavesScreen(),
    AttendanceScreen(),
    ApartmentsScreen(),
    InventoryScreen(),
    CustomersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: PageTransitionSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              return FadeThroughTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Brand.primary,
            border: Border(
              top: BorderSide(color: Color(0x33D4AF37), width: 1),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'الرئيسية'),
                  _buildNavItem(1, Icons.description_outlined, Icons.description, 'الإجازات'),
                  _buildNavItem(2, Icons.calendar_today_outlined, Icons.calendar_today, 'الحضور'),
                  _buildNavItem(3, Icons.apartment_outlined, Icons.apartment, 'الشقق'),
                  _buildNavItem(4, Icons.search, Icons.search, 'تصفّح'),
                  _buildNavItem(5, Icons.people_outline, Icons.people, 'العملاء'),
                  _buildNavItem(6, Icons.person_outline, Icons.person, 'الملف'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isActive ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey<bool>(isActive),
                    size: 24,
                    color: isActive ? Brand.gold : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Brand.gold : const Color(0xFF9CA3AF),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
