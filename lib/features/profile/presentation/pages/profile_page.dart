import 'dart:convert';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'edit_profile_page.dart';
import 'address_page.dart';
import 'help_center_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Memuat...';
  String _userEmail = 'Memuat...';
  String _photoBase64 = '';
  String _userAddress = 'Memuat alamat...';
  int _visits = 0;
  int _elitePoints = 0;
  String _userRole = 'customer';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserAddress();
    profileUpdateNotifier.addListener(_loadUserProfile);
    profileUpdateNotifier.addListener(_loadUserAddress);
  }

  @override
  void dispose() {
    profileUpdateNotifier.removeListener(_loadUserProfile);
    profileUpdateNotifier.removeListener(_loadUserAddress);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');
      if (mounted && userRole != null) {
        setState(() {
          _userRole = userRole;
        });
      }

      if (userId != null && userId.isNotEmpty) {
        final url = Uri.parse(
          'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_profile.php',
        );
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
            if (data != null) {
              setState(() {
                _userName = data['name'] ?? 'Pengguna';
                _userEmail = data['email'] ?? 'Email tidak tersedia';
                _photoBase64 = data['photo'] ?? '';
                _visits = int.tryParse(data['visits']?.toString() ?? '0') ?? 0;
                _elitePoints = int.tryParse(data['elite_points']?.toString() ?? '0') ?? 0;
              });
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) {}
    }
  }

  Future<void> _loadUserAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null && userId.isNotEmpty) {
        final url = Uri.parse(
          'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/manage_address.php',
        );
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'action': 'get'}),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['status'] == 'success') {
            final data = jsonResponse['data'] as List;
            if (data.isNotEmpty) {
              setState(() {
                _userAddress = data[0]['address'];
              });
            } else {
              setState(() {
                _userAddress = 'Belum ada alamat tersimpan';
              });
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userAddress = 'Gagal memuat alamat';
      });
    }
  }

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
  final Color dangerColor = const Color(0xFFDC2626); // Red untuk logout

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildMenuList(),
                    const SizedBox(height: 32),
                    _buildLogoutButton(context), // Parsing context ke method
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ); // <-- AI sebelumnya ngehapus kurung penutup Scaffold ini bro!
  }

  // --- WIDGET MODULAR ---

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: bgColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Profil Saya',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // 1. Munculkan Popup Ala WhatsApp
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bagian atas Dialog (Nama User)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                            ),
                          ),
                        ),
                        // Bagian Foto Square
                        GestureDetector(
                          onTap: () {
                            // 2. Ganti dialog dengan Fullscreen Zoom (InteractiveViewer)
                            Navigator.pushReplacement(
                              dialogContext,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (context, _, _) {
                                  return Scaffold(
                                    backgroundColor: Colors.black,
                                    appBar: AppBar(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      iconTheme: const IconThemeData(color: Colors.white),
                                    ),
                                    body: InteractiveViewer(
                                      minScale: 1.0,
                                      maxScale: 5.0,
                                      child: Hero(
                                        tag: 'profile_pic_hero',
                                        child: Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          alignment: Alignment.center,
                                          child: (_photoBase64.isNotEmpty && _photoBase64.length > 100)
                                              ? Image.memory(
                                                  base64Decode(_photoBase64),
                                                  width: double.infinity,
                                                  fit: BoxFit.contain,
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  height: MediaQuery.of(context).size.width,
                                                  color: const Color(0xFFE2E8F0),
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 200,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                            child: Hero(
                              tag: 'profile_pic_hero',
                              child: (_photoBase64.isNotEmpty && _photoBase64.length > 100)
                                  ? Image.memory(
                                      base64Decode(_photoBase64),
                                      width: double.infinity,
                                      height: MediaQuery.of(dialogContext).size.width - 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: MediaQuery.of(dialogContext).size.width - 80,
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.person, size: 150, color: Color(0xFF94A3B8)),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Hero(
              tag: 'profile_pic_hero',
              child: (_photoBase64.isNotEmpty && _photoBase64.length > 100)
                  ? Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: primaryColor, width: 2),
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(_photoBase64)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: primaryColor, width: 2),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 64,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(_userEmail, style: TextStyle(fontSize: 14, color: textTertiary)),
          const SizedBox(height: 24),
          Divider(color: outlineColor),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('$_visits', 'KUNJUNGAN'),
              Container(
                height: 40,
                width: 1,
                color: outlineColor,
                margin: const EdgeInsets.symmetric(horizontal: 32),
              ),
              _buildStatItem('$_elitePoints', 'POIN ELITE'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textTertiary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList() {
    return Column(
      children: [
        // Menu 1: Edit Profil (Sudah disambungkan ke EditProfilePage)
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'Edit Profil',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfilePage()),
            );
          },
        ),
        const SizedBox(height: 8),

        // Menu 2: Alamat (Hanya tampil jika bukan admin)
        if (_userRole != 'admin') ...[
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Alamat Tersimpan',
            subtitle: _userAddress,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddressPage()),
              );
              _loadUserAddress();
            },
          ),
          const SizedBox(height: 8),
        ],

        // Menu 3: Bantuan
        _buildMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Pusat Bantuan',
          subtitle: 'FAQ & Customer Service',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HelpCenterPage(userRole: _userRole),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Menu 4: Tema
        _buildThemeToggleItem(),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: onSurfaceColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleItem() {
    return InkWell(
      onTap: () {
        setState(() {
          _isDarkMode = !_isDarkMode;
        });
        themeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(
                Icons.palette_outlined,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Tema Tampilan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: onSurfaceColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1F2937) : bgColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: outlineColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: !_isDarkMode ? primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: !_isDarkMode
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      Icons.light_mode,
                      color: !_isDarkMode ? Colors.white : textTertiary,
                      size: 16,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isDarkMode ? primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: _isDarkMode
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.dark_mode_outlined,
                      color: _isDarkMode ? Colors.white : textTertiary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        } catch (e) {
          if (!context.mounted) return;
          SnackbarUtils.showError(context, 'Gagal logout: $e');
        }
      },
      icon: Icon(Icons.logout, color: dangerColor),
      label: Text(
        'Keluar (Logout)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: dangerColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: dangerColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
