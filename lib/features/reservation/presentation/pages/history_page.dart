import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
        padding: const EdgeInsets.all(20),
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

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildReservationCard(
              id: res['reservation_id'].toString(),
              status: statusText,
              rawStatus: rawStatus,
              statusColor: statusColor,
              barberName: res['barber_name'] ?? '-',
              date: _formatDate(res['reservation_date'] ?? ''),
              serviceName: res['service_name'] ?? '-',
              price: 'Rp ${res['service_price'] ?? '0'}',
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (ID & Status)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#RES-$id',
                style: TextStyle(
                  fontSize: 12,
                  color: textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: outlineColor, height: 1),
          ),

          // Barber Info & Date
          Row(
            children: [
              Icon(Icons.content_cut, size: 16, color: textTertiary),
              const SizedBox(width: 8),
              Text(
                'Barber: $barberName',
                style: TextStyle(fontSize: 14, color: onSurfaceColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: textTertiary),
              const SizedBox(width: 8),
              Text(date, style: TextStyle(fontSize: 14, color: textTertiary)),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: outlineColor, height: 1),
          ),

          // Service & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                serviceName,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurfaceColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Tombol Batal
          if (rawStatus == 'pending' || rawStatus == 'confirmed') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: dangerColor,
                  side: BorderSide(color: dangerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Batalkan Reservasi'),
              ),
            ),
          ] else if (rawStatus == 'cancel_requested') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menunggu persetujuan admin untuk pembatalan.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
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
