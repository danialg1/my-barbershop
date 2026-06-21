import 'dart:convert';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_webview_page.dart';

class ReservationFormPage extends StatefulWidget {
  final String? initialServiceId;
  final String? initialServiceName;
  final String? initialBarberId;
  final String? initialBarberName;

  const ReservationFormPage({
    super.key,
    this.initialServiceId,
    this.initialServiceName,
    this.initialBarberId,
    this.initialBarberName,
  });

  @override
  State<ReservationFormPage> createState() => _ReservationFormPageState();
}

class _ReservationFormPageState extends State<ReservationFormPage> {
  bool _isLoading = false;

  // Palet Warna
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

  // State Variables untuk Form
  String? _selectedServiceId;
  List<dynamic> _servicesList = [];
  bool _isLoadingServices = true;
  String? _selectedBarberId;
  List<dynamic> _barbersList = [];
  bool _isLoadingBarbers = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:00';
  final TextEditingController _noteController = TextEditingController();

  int _elitePoints = 0;
  bool _useDiscount = false;
  bool _isLoadingProfile = true;

  final List<String> _timeSlots = [
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '19:00',
    '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchBarbers();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null && userId.isNotEmpty) {
        final url = Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_profile.php');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId}),
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['status'] == 'success') {
            final data = jsonResponse['data'];
            setState(() {
              _elitePoints = int.tryParse(data['elite_points']?.toString() ?? '0') ?? 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _fetchServices() async {
    try {
      final url = Uri.parse(
        'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_services.php',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (mounted) {
            setState(() {
              _servicesList = jsonResponse['data'] ?? [];

              if (widget.initialServiceId != null &&
                  _servicesList.any(
                    (s) => s['id'].toString() == widget.initialServiceId,
                  )) {
                _selectedServiceId = widget.initialServiceId;
              } else if (_servicesList.isNotEmpty) {
                _selectedServiceId = _servicesList[0]['id'].toString();
              }

              _isLoadingServices = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  Future<void> _fetchBarbers() async {
    try {
      final url = Uri.parse(
        'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_barbers.php',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (mounted) {
            setState(() {
              _barbersList = jsonResponse['data'] ?? [];
              
              if (widget.initialBarberId != null &&
                  _barbersList.any(
                    (b) => b['id'].toString() == widget.initialBarberId,
                  )) {
                _selectedBarberId = widget.initialBarberId;
              } else if (_barbersList.isNotEmpty) {
                _selectedBarberId = _barbersList[0]['id'].toString();
              }
              
              _isLoadingBarbers = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBarbers = false;
        });
      }
    }
  }

  // Helper untuk format tanggal sederhana
  String _formatDate(DateTime date) {
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurfaceColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Form Reservasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('1. PILIH LAYANAN'),
            if (_isLoadingServices)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_servicesList.isEmpty)
              Text(
                'Tidak ada layanan tersedia',
                style: TextStyle(color: textTertiary),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: outlineColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedServiceId,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: textTertiary),
                    items: _servicesList.map((dynamic service) {
                      return DropdownMenuItem<String>(
                        value: service['id'].toString(),
                        child: Row(
                          children: [
                            Icon(
                              Icons.content_cut,
                              size: 20,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${service['name']} (Rp ${service['price']})',
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedServiceId = val),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            _buildSectionLabel('2. PILIH BARBER'),
            if (_isLoadingBarbers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_barbersList.isEmpty)
              Text(
                'Tidak ada barber tersedia',
                style: TextStyle(color: textTertiary),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: outlineColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBarberId,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: textTertiary),
                    items: _barbersList.map((dynamic barber) {
                      return DropdownMenuItem<String>(
                        value: barber['id'].toString(),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 20,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              barber['name'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBarberId = val),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            _buildSectionLabel('3. JADWAL (TANGGAL)'),
            _buildDatePicker(),
            const SizedBox(height: 24),

            _buildSectionLabel('4. PILIH JAM'),
            _buildTimeSlots(),
            const SizedBox(height: 24),

            _buildSectionLabel('5. CATATAN TAMBAHAN (OPSIONAL)'),
            _buildNoteField(),
            const SizedBox(height: 32),

            _buildSummaryCard(),
            const SizedBox(height: 24),

            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET MODULAR ---

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(
                        primary: primaryColor,
                        onPrimary: Colors.white,
                        onSurface: Colors.white,
                      )
                    : ColorScheme.light(
                        primary: primaryColor,
                        onPrimary: Colors.white,
                        onSurface: onSurfaceColor,
                      ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineColor),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, size: 20, color: primaryColor),
            const SizedBox(width: 12),
            Text(
              _formatDate(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                color: onSurfaceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit_calendar, size: 18, color: textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _timeSlots.map((time) {
        final isSelected = time == _selectedTime;
        return InkWell(
          onTap: () => setState(() => _selectedTime = time),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? primaryColor : outlineColor,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : onSurfaceColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Cth: Bang, saya mau model rambut pompadour ya...',
        hintStyle: TextStyle(color: textTertiary, fontSize: 14),
        filled: true,
        fillColor: surfaceColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  String _getSelectedServiceName() {
    if (_selectedServiceId == null || _servicesList.isEmpty) return '-';
    final service = _servicesList.firstWhere(
      (s) => s['id'].toString() == _selectedServiceId,
      orElse: () => null,
    );
    return service?['name']?.toString() ?? '-';
  }

  String _getSelectedServicePrice() {
    if (_selectedServiceId == null || _servicesList.isEmpty) return '0';
    final service = _servicesList.firstWhere(
      (s) => s['id'].toString() == _selectedServiceId,
      orElse: () => null,
    );
    return service?['price']?.toString() ?? '0';
  }

  int _getSelectedServicePriceAsInt() {
    return int.tryParse(_getSelectedServicePrice()) ?? 0;
  }

  String _getSelectedBarberName() {
    if (_selectedBarberId == null || _barbersList.isEmpty) return '-';
    final barber = _barbersList.firstWhere(
      (b) => b['id'].toString() == _selectedBarberId,
      orElse: () => null,
    );
    return barber?['name']?.toString() ?? '-';
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Pemesanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Layanan', _getSelectedServiceName()),
          _buildSummaryRow('Barber', _getSelectedBarberName()),
          _buildSummaryRow(
            'Jadwal',
            '${_formatDate(_selectedDate)}, $_selectedTime WIB',
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Harga',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textTertiary,
                  decoration: _useDiscount ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                'Rp ${_getSelectedServicePrice()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _useDiscount ? textTertiary : onSurfaceColor,
                  decoration: _useDiscount ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          if (_useDiscount) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Setelah Diskon (50%)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Rp ${(_getSelectedServicePriceAsInt() / 2).toInt()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (!_isLoadingProfile && _elitePoints >= 25)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pakai 25 Poin Elite',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'Diskon 50% untuk pesanan ini! (Poin: $_elitePoints)',
                          style: TextStyle(fontSize: 12, color: textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useDiscount,
                    activeThumbColor: primaryColor,
                    onChanged: (val) {
                      setState(() {
                        _useDiscount = val;
                      });
                    },
                  ),
                ],
              ),
            )
          else if (!_isLoadingProfile && _elitePoints < 25)
            Text(
              'Kumpulkan 25 Poin Elite untuk diskon 50%! (Poin: $_elitePoints)',
              style: TextStyle(fontSize: 12, color: primaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: textTertiary),
            ),
          ),
          const Text(
            ':  ',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onSurfaceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        SnackbarUtils.showError(context, 'Error: Anda belum login.');
        return;
      }

      final dateStr =
          '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final reservationDate = '$dateStr $_selectedTime:00';

      final url = Uri.parse(
        'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/create_payment.php',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'reservation_date': reservationDate,
          'barber_id': _selectedBarberId,
          'service_id': _selectedServiceId,
          'use_discount': _useDiscount,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final paymentUrl = jsonResponse['payment_url'];
          if (paymentUrl != null && paymentUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebviewPage(url: paymentUrl),
              ),
            );
          } else {
            SnackbarUtils.showSuccess(context, 'Reservasi berhasil!');
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        } else {
          SnackbarUtils.showError(
            context,
            jsonResponse['message'] ?? 'Gagal membuat pembayaran.',
          );
        }
      } else {
        SnackbarUtils.showError(context, 'Terjadi kesalahan pada server.');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _processPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: primaryColor.withValues(alpha: 0.5),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Konfirmasi & Bayar Lunas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
