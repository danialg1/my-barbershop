import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Palet Warna Sesuai Desain
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

  List<dynamic> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      // Caching Mechanism
      final cachedHistory = prefs.getString('cached_history_$userId');
      if (cachedHistory != null && mounted && _reservations.isEmpty) {
        setState(() {
          _reservations = jsonDecode(cachedHistory);
          _isLoading = false;
        });
      }

      final url = Uri.parse(
        'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_user_history.php',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          // Update Cache
          await prefs.setString('cached_history_$userId', jsonEncode(jsonResponse['data'] ?? []));
          
          if (mounted) {
            setState(() {
              _reservations = jsonResponse['data'] ?? [];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      return '${date.day} ${months[date.month - 1]} ${date.year}, $time WIB';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _reservations
        .where(
          (r) =>
              r['status'] == 'pending' ||
              r['status'] == 'confirmed' ||
              r['status'] == 'in_progress' ||
              r['status'] == 'cancel_requested',
        )
        .toList();
    final completedList = _reservations
        .where((r) => r['status'] == 'completed')
        .toList();
    final canceledList = _reservations
        .where((r) => r['status'] == 'rejected' || r['status'] == 'canceled' || r['status'] == 'cancelled')
        .toList();

    // Menggunakan DefaultTabController untuk memanage 3 Tab secara otomatis
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(
            'Riwayat Reservasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurfaceColor,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: textTertiary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Aktif'),
              Tab(text: 'Selesai'),
              Tab(text: 'Dibatalkan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(activeList),
            _buildList(completedList),
            _buildList(canceledList),
          ],
        ),
      ),
    );
  }

  // --- WIDGET MODULAR ---

  Widget _buildList(List<dynamic> data) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchHistory,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Belum ada riwayat',
                  style: TextStyle(color: textTertiary),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final res = data[index];
          final String rawStatus = res['status'] ?? '';
          String statusText = rawStatus;
          Color statusColor = outlineColor;

          if (rawStatus == 'pending') {
            statusText = 'Menunggu Konfirmasi';
            statusColor = primaryColor;
          } else if (rawStatus == 'confirmed') {
            statusText = 'Dikonfirmasi';
            statusColor = Colors.blue;
          } else if (rawStatus == 'in_progress') {
            statusText = 'Sedang Berjalan';
            statusColor = Colors.blue;
          } else if (rawStatus == 'completed') {
            statusText = 'Selesai';
            statusColor = Colors.green;
          } else if (rawStatus == 'rejected') {
            statusText = 'Ditolak';
            statusColor = dangerColor;
          } else if (rawStatus == 'canceled' || rawStatus == 'cancelled') {
            statusText = 'Dibatalkan';
            statusColor = textTertiary;
          } else if (rawStatus == 'cancel_requested') {
            statusText = 'Menunggu Batal';
            statusColor = Colors.orange;
          }

          return _buildReservationCard(
            id: res['reservation_id'].toString(),
            status: statusText,
            rawStatus: rawStatus,
            statusColor: statusColor,
            barberName: res['barber_name'] ?? '-',
            date: _formatDate(res['reservation_date'] ?? ''),
            serviceName: res['service_name'] ?? '-',
            price: 'Rp ${res['service_price'] ?? '0'}',
          );
        },
      ),
    );
  }

  Widget _buildReservationCard({
    required String id,
    required String status,
    required String rawStatus,
    required Color statusColor,
    required String barberName,
    required String date,
    required String serviceName,
    required String price,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Shop Info & Status)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront, size: 18, color: onSurfaceColor),
                    const SizedBox(width: 8),
                    Text(
                      'My Barbershop',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: textTertiary),
                  ],
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: outlineColor),
          
          // 2. Item Body (Image, Service, Barber, Price)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outlineColor),
                  ),
                  child: Center(
                    child: Icon(Icons.content_cut, color: textTertiary, size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Barber: $barberName',
                        style: TextStyle(fontSize: 12, color: textTertiary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(fontSize: 12, color: textTertiary),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurfaceColor,
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Order Tracking Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1F2937).withValues(alpha: 0.5) : const Color(0xFFF9FAFB),
            child: Row(
              children: [
                Icon(
                  _getProgressIcon(rawStatus), 
                  size: 20, 
                  color: _getProgressColor(rawStatus),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getProgressText(rawStatus),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getProgressColor(rawStatus),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: textTertiary),
              ],
            ),
          ),
          
          // 4. Total Harga
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 Layanan',
                  style: TextStyle(fontSize: 12, color: textTertiary),
                ),
                Row(
                  children: [
                    Text(
                      'Total Pesanan: ',
                      style: TextStyle(fontSize: 13, color: onSurfaceColor),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: outlineColor),
          
          // 5. Action Buttons
          if (_hasActionButtons(rawStatus))
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(id, rawStatus),
              ),
            ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideX(begin: 0.1, end: 0);
  }

  IconData _getProgressIcon(String rawStatus) {
    switch (rawStatus) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.thumb_up_alt_outlined;
      case 'in_progress':
        return Icons.cut_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancel_requested':
        return Icons.pending_actions;
      case 'canceled':
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getProgressText(String rawStatus) {
    switch (rawStatus) {
      case 'pending':
        return 'Pesanan telah dibuat dan menunggu pembayaran/konfirmasi.';
      case 'confirmed':
        return 'Pesanan telah dikonfirmasi oleh Admin. Silakan datang ke lokasi.';
      case 'in_progress':
        return 'Layanan sedang berlangsung.';
      case 'completed':
        return 'Pesanan telah selesai. Terima kasih!';
      case 'cancel_requested':
        return 'Permintaan pembatalan sedang ditinjau.';
      case 'canceled':
      case 'cancelled':
        return 'Pesanan telah dibatalkan.';
      case 'rejected':
        return 'Pesanan ditolak oleh sistem/admin.';
      default:
        return 'Memproses pesanan...';
    }
  }

  Color _getProgressColor(String rawStatus) {
    if (rawStatus == 'completed') return Colors.green;
    if (rawStatus == 'canceled' || rawStatus == 'cancelled' || rawStatus == 'rejected') return dangerColor;
    if (rawStatus == 'cancel_requested') return Colors.orange;
    return Colors.blue; 
  }

  bool _hasActionButtons(String rawStatus) {
    return rawStatus == 'pending' || rawStatus == 'confirmed' || rawStatus == 'cancel_requested';
  }

  List<Widget> _buildActionButtons(String id, String rawStatus) {
    if (rawStatus == 'pending' || rawStatus == 'confirmed') {
      return [
        OutlinedButton(
          onPressed: () => _showCancelDialog(id),
          style: OutlinedButton.styleFrom(
            foregroundColor: onSurfaceColor,
            side: BorderSide(color: outlineColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Batalkan Pesanan'),
        ),
      ];
    } else if (rawStatus == 'cancel_requested') {
      return [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menunggu persetujuan pembatalan',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [];
  }

  void _showCancelDialog(String reservationId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          title: Text('Alasan Pembatalan', style: TextStyle(color: onSurfaceColor)),
          content: TextField(
            controller: reasonCtrl,
            style: TextStyle(color: onSurfaceColor),
            decoration: InputDecoration(
              hintText: 'Contoh: Ada urusan mendadak',
              hintStyle: TextStyle(color: textTertiary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: outlineColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup', style: TextStyle(color: textTertiary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonCtrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                
                setState(() => _isLoading = true);
                try {
                  await http.post(
                    Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/request_cancel.php'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'reservation_id': reservationId,
                      'cancel_reason': reasonCtrl.text.trim(),
                    }),
                  );
                } finally {
                  _fetchHistory();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: dangerColor),
              child: const Text('Kirim Permintaan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
