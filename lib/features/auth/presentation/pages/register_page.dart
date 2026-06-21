import 'dart:convert';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // -- DYNAMIC THEME PALETTE --
  // Palet dinamis ini akan secara otomatis merespon perubahan tema (terang/gelap)
  // yang diatur pada aplikasi (Theme.of(context).brightness).
  // Dengan ini, warna akan selaras dengan pengaturan global di profil.
  final Color primaryColor = const Color(0xFFD4AF37); // Gold
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor =>
      isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
  Color get surfaceColor =>
      isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
  Color get onSurfaceColor => isDark ? Colors.white : const Color(0xFF111827);
  Color get textTertiary =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get outlineColor =>
      isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  final Color dangerColor = const Color(0xFFDC2626); // Red

  // Controllers untuk menangkap teks inputan
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- FUNGSI REGISTRASI API LOKAL ---
  Future<void> _registerUser() async {
    // 1. Validasi sederhana
    if (_passwordController.text != _confirmPasswordController.text) {
      SnackbarUtils.showError(
        context,
        'Password dan Konfirmasi Password tidak sama!',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Kirim data ke REST API
      final url = Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/register.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'phone': _phoneController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' ||
            data['status'] == 'success_no_email') {
          // Navigasi ke halaman Verifikasi OTP
          if (!mounted) return;
          SnackbarUtils.showSuccess(
            context,
            data['message'] ?? 'Registrasi berhasil!',
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EmailVerificationPage(email: _emailController.text.trim()),
            ),
          );
        } else {
          // Tampilkan pesan error dari PHP
          if (!mounted) return;
          SnackbarUtils.showError(
            context,
            data['message'] ?? 'Gagal mendaftar.',
          );
        }
      } else {
        SnackbarUtils.showError(context, 'Terjadi kesalahan pada server.');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Koneksi gagal: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alias untuk kompatibilitas variabel ke palet dinamis di atas
    final backgroundColor = bgColor;
    final onSurfaceVariantColor = textTertiary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: onSurfaceColor),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Text(
                    'MY BARBERSHOP',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 2.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Buat Akun Baru',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        height: 1.25,
                        letterSpacing: -0.64,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bergabunglah untuk pengalaman pangkas rambut premium.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: onSurfaceVariantColor,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    // Forms
                    _CustomTextField(
                      label: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: Icons.person_outline,
                      controller: _nameController,
                    ),
                    SizedBox(height: 16),
                    _CustomTextField(
                      label: 'Email',
                      hintText: 'nama@email.com',
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    SizedBox(height: 16),
                    _CustomTextField(
                      label: 'Password',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      controller: _passwordController,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: primaryColor,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _CustomTextField(
                      label: 'Konfirmasi Password',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_reset_outlined,
                      obscureText: _obscureConfirmPassword,
                      controller: _confirmPasswordController,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: primaryColor,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _CustomTextField(
                      label: 'No Handphone',
                      hintText: '0812-3456-7890',
                      prefixIcon: Icons.phone_iphone_outlined,
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                    ),
                    SizedBox(height: 16),
                    _CustomTextField(
                      label: 'Alamat',
                      hintText: 'Jl. Ahmad Yani, Pontianak',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      controller: _addressController,
                    ),
                    SizedBox(height: 32),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: onSurfaceColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: onSurfaceColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Daftar Sekarang',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: onSurfaceVariantColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Masuk di sini',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final TextEditingController? controller; // Tambahan Controller

  const _CustomTextField({
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFD4AF37);
    final surfaceColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariantColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final outlineVariantColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label.toUpperCase(),
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
            border: Border.all(color: outlineVariantColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller, // Pasang controller di sini
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: onSurfaceColor,
              letterSpacing: obscureText ? 2.0 : null,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: onSurfaceVariantColor.withValues(alpha: 0.5),
                fontFamily: 'Inter',
                letterSpacing: obscureText ? 2.0 : null,
              ),
              prefixIcon: Icon(prefixIcon, color: primaryColor),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
