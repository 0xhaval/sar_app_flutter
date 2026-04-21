import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usrController = TextEditingController();
  final _pwdController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _handleLogin() async {
    final usr = _usrController.text.trim();
    final pwd = _pwdController.text;

    if (usr.isEmpty || pwd.isEmpty) {
      setState(() => _error = 'يرجى إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.login(usr, pwd);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usrController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF284A63),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset('assets/logo.png', color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SAR Employee',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF284A63),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تسجيل الدخول إلى حسابك',
                    style: TextStyle(fontSize: 16, color: Color(0xFF353535)),
                  ),
                  const SizedBox(height: 40),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username field
                  TextField(
                    controller: _usrController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    controller: _pwdController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF284A63),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF284A63).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
