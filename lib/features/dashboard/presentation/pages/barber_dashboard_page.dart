import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../notification/presentation/pages/notification_page.dart';

class BarberDashboardPage extends StatefulWidget {
  const BarberDashboardPage({super.key});

  @override
  State<BarberDashboardPage> createState() => _BarberDashboardPageState();
}

class _BarberDashboardPageState extends State<BarberDashboardPage> {
  final Color primaryColor = const Color(0xFFD4AF37); // Gold
  final Color greenColor = Colors.green;
  final Color redColor = const Color(0xFFDC2626);

  bool _isStatusActive = true;
  int _currentIndex = 0;
  List<dynamic> _reservations = [];
  bool _isLoading = true;
  int _monthlyIncome = 0;
  List<dynamic> _servicesList = [];
  bool _isLoadingServices = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchReservations();
    _fetchServices();
    _fetchUnreadCount();
  }

  Future<void> _refreshAll() async {
    await _fetchStats();
    await _fetchReservations();
    await _fetchServices();
    await _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final response = await http.post(
        Uri.parse('http://192.168.1.4/barbershop_api/get_notifications.php'),
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List notifications = data['data'];
          int count = 0;
          for (var notif in notifications) {
            if (notif['is_read'] == 0 || notif['is_read'] == '0') {
              count++;
            }
          }
          if (mounted) {
            setState(() {
              _unreadCount = count;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> _fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final url = Uri.parse(
        'http://192.168.1.4/barbershop_api/get_barber_stats.php',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barber_id': userId}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (mounted) {
            setState(() {
              _isStatusActive = jsonResponse['data']['is_active'] ?? false;
              _monthlyIncome = jsonResponse['data']['monthly_income'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<void> _toggleStatus(bool val) async {
    setState(() {
      _isStatusActive = val;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final url = Uri.parse(
        'http://192.168.1.4/barbershop_api/update_barber_status.php',
      );
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barber_id': userId, 'is_active': val}),
      );
    } catch (e) {
      setState(() {
        _isStatusActive = !val;
      });
      debugPrint('Error updating status: $e');
    }
  }

  Future<void> _fetchReservations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final url = Uri.parse(
        'http://192.168.1.4/barbershop_api/barber_reservations.php',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barber_id': userId, 'action': 'get_schedule'}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (mounted) {
            setState(() {
              _reservations = jsonResponse['data'] ?? [];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchServices() async {
    try {
      final url = Uri.parse(
        'http://192.168.1.4/barbershop_api/get_services.php',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (mounted) {
            setState(() {
              _servicesList = jsonResponse['data'] ?? [];
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

  Future<void> _changeStatus(String reservationId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final url = Uri.parse(
        'http://192.168.1.4/barbershop_api/barber_reservations.php',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barber_id': userId,
          'reservation_id': reservationId,
          'new_status': newStatus,
          'action': 'update_status',
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          _fetchReservations(); // Refresh UI
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme Variables
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF9FAFB);
    final Color surfaceColor = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFFFFFFF);
    final Color onSurfaceColor = isDark
        ? Colors.white
        : const Color(0xFF111827);
    final Color textTertiary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final Color timeBgColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFF3F4F6);

    final List<Widget> pages = [
      _buildDashboardView(
        surfaceColor,
        onSurfaceColor,
        textTertiary,
        timeBgColor,
      ),
      _buildServicesTab(surfaceColor, onSurfaceColor, textTertiary),
      const Center(child: Text('Halaman Laporan')),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Dashboard Barber',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              ).then((_) => _fetchUnreadCount());
            },
            icon: _unreadCount > 0
                ? Badge(
                    label: Text('$_unreadCount'),
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.notifications_none,
                      color: onSurfaceColor,
                    ),
                  )
                : Icon(Icons.notifications_none, color: onSurfaceColor),
          ),
          Row(
            children: [
              Text(
                'Status Aktif',
                style: TextStyle(
                  color: textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _isStatusActive,
                activeThumbColor: primaryColor,
                onChanged: _toggleStatus,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _fetchUnreadCount();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.room_service),
            label: 'Layanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
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
      final String time =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return '${date.day} ${months[date.month - 1]} ${date.year} • $time WIB';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatCurrency(int amount) {
    String res = amount.toString();
    String formatted = '';
    for (int i = 0; i < res.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = res[res.length - 1 - i] + formatted;
    }
    return 'Rp $formatted';
  }

  Widget _buildServicesTab(
    Color surfaceColor,
    Color onSurfaceColor,
    Color textTertiary,
  ) {
    return RefreshIndicator(
      onRefresh: _fetchServices,
      child: _isLoadingServices
          ? const Center(child: CircularProgressIndicator())
          : _servicesList.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Text(
                      'Belum ada layanan tersedia',
                      style: TextStyle(color: textTertiary),
                    ),
                  ),
                ),
              ],
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _servicesList.length,
              itemBuilder: (context, index) {
                final service = _servicesList[index];
                return Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            service['image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.room_service,
                                    color: primaryColor,
                                    size: 40,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${service['price']}',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDashboardView(
    Color surfaceColor,
    Color onSurfaceColor,
    Color textTertiary,
    Color timeBgColor,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reservasi Hari Ini',
                        style: TextStyle(
                          color: textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_reservations.length}',
                        style: TextStyle(
                          color: onSurfaceColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pendapatan',
                        style: TextStyle(
                          color: textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrency(_monthlyIncome),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Jadwal Hari Ini
          Text(
            'Daftar Antrean',
            style: TextStyle(
              color: onSurfaceColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // List of Schedules
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_reservations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Belum ada antrean masuk',
                  style: TextStyle(color: textTertiary),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reservations.length,
              itemBuilder: (context, index) {
                final res = _reservations[index];
                String timeStr = _formatDate(res['reservation_date'] ?? '');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildScheduleCard(
                    context: context,
                    surfaceColor: surfaceColor,
                    onSurfaceColor: onSurfaceColor,
                    textTertiary: textTertiary,
                    timeBgColor: timeBgColor,
                    name: res['customer_name'] ?? 'Unknown',
                    service: res['service_name'] ?? 'Layanan',
                    time: timeStr,
                    status: res['status'] ?? 'pending',
                    reservationId: res['reservation_id']?.toString() ?? '',
                    cancelReason: res['cancel_reason'],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required BuildContext context,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required Color textTertiary,
    required Color timeBgColor,
    required String name,
    required String service,
    required String time,
    required String status,
    required String reservationId,
    String? cancelReason,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                child: Icon(Icons.person, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service,
                      style: TextStyle(color: textTertiary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(time, style: TextStyle(color: textTertiary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Bottom Row (Status actions)
          _buildStatusActions(status, reservationId, cancelReason),
        ],
      ),
    );
  }

  Widget _buildStatusActions(String status, String reservationId, String? cancelReason) {
    if (status == 'pending') {
      // Menunggu Konfirmasi
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: redColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'Menunggu Konfirmasi',
                style: TextStyle(
                  color: redColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _changeStatus(reservationId, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: redColor,
                    side: BorderSide(color: redColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tolak',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _changeStatus(reservationId, 'confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Terima',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (status == 'confirmed') {
      // DP Lunas
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: greenColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'DP Lunas / Dikonfirmasi',
                style: TextStyle(
                  color: greenColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _changeStatus(reservationId, 'in_progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mulai Layanan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'in_progress') {
      // Sedang Berlangsung
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, color: primaryColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'Sedang Berlangsung',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _changeStatus(reservationId, 'completed'),
              style: OutlinedButton.styleFrom(
                foregroundColor: greenColor,
                side: BorderSide(color: greenColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'cancel_requested') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Text(
                'Permintaan Pembatalan',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alasan Pelanggan:',
                  style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  cancelReason ?? '-',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleCancelRequest(reservationId, 'reject_cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: redColor,
                    side: BorderSide(color: redColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleCancelRequest(reservationId, 'approve_cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Terima', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _handleCancelRequest(String reservationId, String action) async {
    try {
      await http.post(
        Uri.parse('http://192.168.1.4/barbershop_api/update_reservation.php'),
        body: jsonEncode({
          'reservation_id': reservationId,
          'action': action,
        }),
      );
      _fetchReservations(); // Refresh jadwal
    } catch (e) {
      // ignore
    }
  }
}
