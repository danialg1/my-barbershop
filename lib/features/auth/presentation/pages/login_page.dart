import 'dart:convert';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../dashboard/presentation/pages/main_screen.dart';
import '../../../dashboard/presentation/pages/barber_dashboard_page.dart';
import '../../../dashboard/presentation/pages/admin_dashboard_page.dart';
import 'register_page.dart';
import 'email_verification_page.dart';
import 'forgot_password_page.dart';
import '../../../../core/services/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Color primaryColor = const Color(0xFFD4AF37); // Gold
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor =>
      isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
  Color get surfaceColor =>
      isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
  Color get onSurfaceColor => isDark ? Colors.white : const Color(0xFF111827);
  Color get textTertiary =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get onSurfaceVariantColor =>
      isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);
  Color get outlineColor =>
      isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  final Color dangerColor = const Color(0xFFDC2626); // Red

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final String email = googleUser.email;
      final String displayName = googleUser.displayName ?? 'Google User';
      final String photoUrl = googleUser.photoUrl ?? '';

      final url = Uri.parse(
        'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/google_login.php',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': displayName,
          'photoUrl': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          final data = jsonResponse['data'];
          await prefs.setString('user_id', data['id'].toString());
          await prefs.setString('user_name', data['name'].toString());
          await prefs.setString('user_role', data['role'] ?? 'customer');

          // Upload FCM Token
          try {
            NotificationService.uploadFcmToken();
          } catch (_) {}

          if (!mounted) return;
          if (data['role'] == 'barber') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const BarberDashboardPage(),
              ),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          }
        } else {
          if (!mounted) return;
          SnackbarUtils.showError(
            context,
            jsonResponse['message'] ?? 'Login Google Gagal',
          );
        }
      } else {
        if (!mounted) return;
        SnackbarUtils.showError(context, 'Terjadi kesalahan pada server.');
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('canceled') ||
          e.toString().contains('Canceled')) {
        return;
      }
      SnackbarUtils.showError(context, 'Koneksi gagal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = bgColor;
    final onSurfaceVariantColor = textTertiary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // Logo Section
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: onSurfaceColor,
                            letterSpacing: -0.64,
                            height: 1.25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Masuk untuk melanjutkan pengalaman premium Anda.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: onSurfaceVariantColor,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Form Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email Field
                        Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 4),
                          child: Text(
                            'EMAIL',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: onSurfaceVariantColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: outlineColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: onSurfaceColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'contoh@email.com',
                              hintStyle: TextStyle(
                                color: Color(0x806B7280),
                                fontFamily: 'Inter',
                              ),
                              prefixIcon: Icon(
                                Icons.mail_outline,
                                color: onSurfaceVariantColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Password Field
                        Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 4),
                          child: Text(
                            'PASSWORD',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: onSurfaceVariantColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: outlineColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: onSurfaceColor,
                              letterSpacing: 2.0,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(
                                color: Color(0x806B7280),
                                fontFamily: 'Inter',
                                letterSpacing: 2.0,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: onSurfaceVariantColor,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: onSurfaceVariantColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Login Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    try {
                                      final url = Uri.parse(
                                        'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/login.php',
                                      );
                                      final response = await http.post(
                                        url,
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          'email': _emailController.text.trim(),
                                          'password': _passwordController.text
                                              .trim(),
                                        }),
                                      );

                                      if (response.statusCode == 200) {
                                        final jsonResponse = jsonDecode(
                                          response.body,
                                        );

                                        if (jsonResponse['status'] ==
                                            'success') {
                                          final prefs =
                                              await SharedPreferences.getInstance();
                                          final data = jsonResponse['data'];
                                          await prefs.setString(
                                            'user_id',
                                            data['id'].toString(),
                                          );
                                          await prefs.setString(
                                            'user_name',
                                            data['name'].toString(),
                                          );
                                          await prefs.setString(
                                            'user_role',
                                            data['role'] ?? 'customer',
                                          );

                                          // Upload FCM Token
                                          try {
                                            NotificationService.uploadFcmToken();
                                          } catch (_) {}

                                          if (!context.mounted) return;
                                          if (data['role'] == 'admin') {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const AdminDashboardPage(),
                                              ),
                                              (route) => false,
                                            );
                                          } else if (data['role'] == 'barber') {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const BarberDashboardPage(),
                                              ),
                                              (route) => false,
                                            );
                                          } else {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const MainScreen(),
                                              ),
                                              (route) => false,
                                            );
                                          }
                                        } else if (jsonResponse['status'] ==
                                            'unverified') {
                                          if (!context.mounted) return;
                                          SnackbarUtils.showInfo(
                                            context,
                                            jsonResponse['message'],
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EmailVerificationPage(
                                                    email: _emailController.text
                                                        .trim(),
                                                  ),
                                            ),
                                          );
                                        } else {
                                          if (!context.mounted) return;
                                          SnackbarUtils.showError(
                                            context,
                                            jsonResponse['message'] ??
                                                'Gagal login.',
                                          );
                                        }
                                      } else {
                                        if (!context.mounted) return;
                                        SnackbarUtils.showError(
                                          context,
                                          'Terjadi kesalahan pada server.',
                                        );
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      SnackbarUtils.showError(
                                        context,
                                        'Koneksi gagal: $e',
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'MASUK',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: outlineColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'ATAU',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: onSurfaceVariantColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: outlineColor)),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Google Login Button
                        _GoogleLoginButton(onPressed: _signInWithGoogle),
                      ],
                    ),

                    const Spacer(),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: onSurfaceVariantColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Daftar di sini',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                                decoration: TextDecoration.underline,
                                decorationColor: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleLoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Colors.white;
    const onSurfaceColor = Color(0xFF111827);
    const outlineColor = Color(0xFFE5E7EB);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: surfaceColor,
          foregroundColor: onSurfaceColor,
          side: BorderSide(color: outlineColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.g_mobiledata, size: 24, color: Colors.blue),
            ),
            SizedBox(width: 12),
            Text(
              'MASUK DENGAN GOOGLE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onSurfaceColor,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
