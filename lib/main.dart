import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_shell.dart';
import 'screens/login.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme/brand.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool _handlingSessionExpiry = false;

Future<void> _onSessionExpired() async {
  if (_handlingSessionExpiry) return;
  _handlingSessionExpiry = true;
  try {
    // Concurrent 401s: only the first one still holding a token proceeds.
    if (!await AuthService.isLoggedIn()) return;
    await AuthService.clearSession();
    Fluttertoast.showToast(msg: 'انتهت الجلسة، يرجى تسجيل الدخول من جديد');
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  } finally {
    _handlingSessionExpiry = false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.onSessionExpired = _onSessionExpired;
  final isLoggedIn = await AuthService.isLoggedIn();
  runApp(PromsApp(isLoggedIn: isLoggedIn));
}

class PromsApp extends StatelessWidget {
  final bool isLoggedIn;

  const PromsApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PROMS',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Brand.primary,
          primary: Brand.primary,
          secondary: Brand.gold,
          surface: Brand.surface,
        ),
        scaffoldBackgroundColor: Brand.surface,
        textTheme: GoogleFonts.tajawalTextTheme(),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          headerBackgroundColor: const Color(0xFF111317),
          headerForegroundColor: Colors.white,
          dayStyle: GoogleFonts.tajawal(fontSize: 14),
          yearStyle: GoogleFonts.tajawal(fontSize: 14),
          todayBorder: const BorderSide(color: Color(0xFF111317), width: 1.5),
          surfaceTintColor: Colors.transparent,
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF111317);
            }
            return null;
          }),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return null;
          }),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          dayPeriodShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          dialHandColor: const Color(0xFF111317),
          dialBackgroundColor: const Color(0xFFD9DAD9),
          hourMinuteColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFD9DAD9);
            }
            return const Color(0xFFF3F4F6);
          }),
          hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF111317);
            }
            return const Color(0xFF353535);
          }),
          hourMinuteTextStyle: GoogleFonts.tajawal(fontSize: 40, fontWeight: FontWeight.w500),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF111317), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
      ),
      home: isLoggedIn ? const AppShell() : const LoginScreen(),
    );
  }
}
