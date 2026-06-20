import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../reservation/presentation/pages/history_page.dart';
import '../../../notification/presentation/pages/notification_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _unreadCount = 0;

  // Daftar halaman yang akan ditukar-tukar
  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(),
    const NotificationPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final response = await http.post(
        Uri.parse('http://192.168.1.5/barbershop_api/get_notifications.php'),
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFFD4AF37);
    final Color surfaceColor = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFFFFFFF);
    final Color textTertiary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final Color outlineColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      // IndexedStack menjaga agar halaman tidak kereload dari awal saat ditukar
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: outlineColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 2) {
              // Jika buka tab Notifikasi, mark as read dan hilangkan badge (akan terefresh dari dalam NotificationPage)
              _fetchUnreadCount();
            } else if (index == 0) {
              // Refresh badge saat buka beranda
              _fetchUnreadCount();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: surfaceColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Beranda',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: _unreadCount > 0
                  ? Badge(
                      label: Text('$_unreadCount'),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.notifications_none),
                    )
                  : const Icon(Icons.notifications_none),
              label: 'Notifikasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
