import 'package:flutter/material.dart';
import '../../../../core/utils/snackbar_utils.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final Color primaryColor = const Color(0xFFD4AF37); // Gold
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
  Color get surfaceColor => isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
  Color get onSurfaceColor => isDark ? Colors.white : const Color(0xFF111827);
  Color get textTertiary => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get outlineColor => isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  final Color dangerColor = const Color(0xFFDC2626); // Red

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Bagaimana cara membatalkan reservasi?',
      'answer': 'Anda dapat membatalkan reservasi paling lambat 2 jam sebelum jadwal dimulai melalui menu Riwayat Transaksi. Biaya pembayaran Anda akan dikembalikan sesuai ketentuan yang berlaku.'
    },
    {
      'question': 'Bagaimana cara menggunakan Poin Elite?',
      'answer': 'Poin Elite dapat ditukarkan secara otomatis saat Anda melakukan pembayaran. Anda bisa memotong total biaya layanan menggunakan akumulasi poin yang Anda miliki.'
    },
    {
      'question': 'Apakah saya bisa datang terlambat?',
      'answer': 'Toleransi keterlambatan adalah 15 menit dari jadwal reservasi. Lebih dari itu, barber berhak melayani pelanggan berikutnya dan Anda akan dijadwalkan ulang sesuai ketersediaan.'
    },
    {
      'question': 'Metode pembayaran apa saja yang tersedia?',
      'answer': 'Kami menerima pembayaran Tunai, QRIS, Transfer Bank (BCA, Mandiri), dan E-Wallet (GoPay, OVO, Dana).'
    },
  ];

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
          'Pusat Bantuan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: outlineColor),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent, // Menghilangkan garis default ExpansionTile
                    ),
                    child: ExpansionTile(
                      iconColor: primaryColor,
                      collapsedIconColor: textTertiary,
                      title: Text(
                        _faqs[index]['question']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: onSurfaceColor,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            _faqs[index]['answer']!,
                            style: TextStyle(
                              color: textTertiary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bagian Tombol CS WhatsApp
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                SnackbarUtils.showInfo(context, 'Mengarahkan ke WhatsApp CS...');
              },
              icon: const Icon(Icons.support_agent, color: Colors.white),
              label: const Text(
                'Hubungi CS via WhatsApp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // Mengikuti tema aplikasi (Gold) sesuai permintaan
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
