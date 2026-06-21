import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/snackbar_utils.dart';

class HelpCenterPage extends StatefulWidget {
  final String userRole;

  const HelpCenterPage({super.key, this.userRole = 'customer'});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFD4AF37); // Gold
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
  Color get surfaceColor => isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
  Color get onSurfaceColor => isDark ? Colors.white : const Color(0xFF111827);
  Color get textTertiary => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get outlineColor => isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  final Color dangerColor = const Color(0xFFDC2626); // Red

  List<dynamic> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCache();
    _fetchFaqs();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedFaqs = prefs.getString('cached_faqs');
    if (cachedFaqs != null) {
      if (mounted) {
        setState(() {
          _faqs = jsonDecode(cachedFaqs);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFaqs() async {
    try {
      final url = Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/crud_faqs.php');
      final response = await http.post(
        url,
        body: jsonEncode({'action': 'read'}),
        headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];
          if (mounted) {
            setState(() {
              _faqs = data;
              _isLoading = false;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_faqs', jsonEncode(data));
          }
        }
      }
    } catch (e) {
      if (mounted && _faqs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        SnackbarUtils.showError(context, 'Gagal memuat FAQ');
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/62895704121560');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Tidak dapat membuka WhatsApp');
      }
    }
  }

  Future<void> _deleteFaq(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus FAQ'),
        content: const Text('Apakah Anda yakin ingin menghapus FAQ ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true) {
      try {
        final url = Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/crud_faqs.php');
        final response = await http.post(
          url,
          body: jsonEncode({'action': 'delete', 'id': id}),
          headers: {'Content-Type': 'application/json'}
        );
        if (response.statusCode == 200) {
          final res = jsonDecode(response.body);
          if (!mounted) return;
          if (res['status'] == 'success') {
            SnackbarUtils.showSuccess(context, 'FAQ berhasil dihapus');
            _fetchFaqs();
          } else {
            SnackbarUtils.showError(context, res['message'] ?? 'Gagal menghapus');
          }
        }
      } catch (e) {
        if (!mounted) return;
        SnackbarUtils.showError(context, 'Terjadi kesalahan: $e');
      }
    }
  }

  void _showFaqDialog(Map<String, dynamic>? faq) {
    final isEdit = faq != null;
    final questionCtrl = TextEditingController(text: isEdit ? faq['question'] : '');
    final answerCtrl = TextEditingController(text: isEdit ? faq['answer'] : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit FAQ' : 'Tambah FAQ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionCtrl,
                decoration: const InputDecoration(labelText: 'Pertanyaan', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerCtrl,
                decoration: const InputDecoration(labelText: 'Jawaban', border: OutlineInputBorder()),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final url = Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/crud_faqs.php');
                final response = await http.post(
                  url,
                  body: jsonEncode({
                    'action': isEdit ? 'update' : 'create',
                    'id': isEdit ? faq['id'] : null,
                    'question': questionCtrl.text,
                    'answer': answerCtrl.text,
                  }),
                  headers: {'Content-Type': 'application/json'}
                );
                if (response.statusCode == 200) {
                  final res = jsonDecode(response.body);
                  if (!mounted) return;
                  if (res['status'] == 'success') {
                    SnackbarUtils.showSuccess(context, res['message']);
                    _fetchFaqs();
                  } else {
                    SnackbarUtils.showError(context, res['message'] ?? 'Gagal menyimpan');
                  }
                }
              } catch (e) {
                if (!mounted) return;
                SnackbarUtils.showError(context, 'Terjadi kesalahan: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
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
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : RefreshIndicator(
                    onRefresh: _fetchFaqs,
                    child: _faqs.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                  child: Text(
                                    'Belum ada pertanyaan sering diajukan',
                                    style: TextStyle(color: textTertiary),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            itemCount: _faqs.length,
                            itemBuilder: (context, index) {
                              final faq = _faqs[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 100)),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: outlineColor),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      iconColor: primaryColor,
                                      collapsedIconColor: textTertiary,
                                      title: Text(
                                        faq['question'],
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
                                            faq['answer'],
                                            style: TextStyle(
                                              color: textTertiary,
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                        if (widget.userRole == 'admin')
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                                  onPressed: () => _showFaqDialog(faq),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _deleteFaq(int.tryParse(faq['id'].toString()) ?? 0),
                                                ),
                                              ],
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
              onPressed: _launchWhatsApp,
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
                backgroundColor: primaryColor,
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
      floatingActionButton: widget.userRole == 'admin'
          ? FloatingActionButton(
              backgroundColor: primaryColor,
              onPressed: () => _showFaqDialog(null),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
