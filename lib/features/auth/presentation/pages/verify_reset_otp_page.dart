import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/snackbar_utils.dart';
import 'reset_password_page.dart';

class VerifyResetOtpPage extends StatefulWidget {
  final String email;

  const VerifyResetOtpPage({super.key, required this.email});

  @override
  State<VerifyResetOtpPage> createState() => _VerifyResetOtpPageState();
}

class _VerifyResetOtpPageState extends State<VerifyResetOtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFFD4AF37);
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor =>
      isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
  Color get surfaceColor =>
      isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
  Color get onSurfaceColor => isDark ? Colors.white : const Color(0xFF111827);
  Color get onSurfaceVariantColor =>
      isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);
  Color get outlineColor =>
      isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto submit if all filled
    if (index == 5 && value.isNotEmpty) {
      bool allFilled = _controllers.every((c) => c.text.isNotEmpty);
      if (allFilled) {
        _verifyOtp();
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      SnackbarUtils.showError(context, 'Silakan masukkan kode OTP lengkap');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/verify_reset_otp.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': otp}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          SnackbarUtils.showSuccess(context, jsonResponse['message']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordPage(email: widget.email, otp: otp),
            ),
          );
        } else {
          SnackbarUtils.showError(
            context,
            jsonResponse['message'] ?? 'OTP tidak valid.',
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurfaceColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mark_email_read, size: 80, color: primaryColor),
              const SizedBox(height: 24),
              Text(
                'Cek Email Anda',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: onSurfaceVariantColor,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Kami telah mengirim kode OTP ke '),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(fontWeight: FontWeight.bold, color: onSurfaceColor),
                    ),
                    const TextSpan(text: '. Masukkan kode tersebut di bawah ini.'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    height: 55,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: outlineColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      onChanged: (value) => _onOtpChanged(value, index),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'VERIFIKASI OTP',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
