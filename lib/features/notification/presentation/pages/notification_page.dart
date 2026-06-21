import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
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

  List<dynamic> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return;

      final response = await http.post(
        Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_notifications.php'),
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            notifications = data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return;

      final response = await http.post(
        Uri.parse(
          'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/mark_notification_read.php',
        ),
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Update state lokal
          setState(() {
            for (var notif in notifications) {
              notif['is_read'] = 1; // atau '1' tergantung tipe dari PHP
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return;

      await http.post(
        Uri.parse(
          'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/mark_notification_read.php',
        ),
        body: jsonEncode({
          'user_id': userId,
          'notification_id': notificationId,
        }),
      );
    } catch (e) {
      debugPrint('Error marking single notification: $e');
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'payment':
        return Icons.payments_outlined;
      case 'reservation':
        return Icons.calendar_month_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Tandai semua dibaca',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: primaryColor,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : notifications.isEmpty
            ? Center(
                child: Text(
                  'Belum ada notifikasi',
                  style: TextStyle(color: textTertiary),
                ),
              )
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  // Pastikan is_read adalah int atau string dari PHP
                  final isRead =
                      notif['is_read'] == 1 || notif['is_read'] == '1';

                  return InkWell(
                    onTap: () {
                      if (!isRead) {
                        setState(() {
                          notif['is_read'] = 1;
                        });
                        _markAsRead(int.parse(notif['id'].toString()));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isRead ? bgColor : surfaceColor,
                        border: Border(bottom: BorderSide(color: outlineColor)),
                        boxShadow: isRead
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isRead
                                  ? outlineColor.withValues(alpha: 0.3)
                                  : bgColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: outlineColor),
                            ),
                            child: Icon(
                              _getIconForType(notif['type'] ?? 'system'),
                              color: isRead
                                  ? textTertiary.withValues(alpha: 0.7)
                                  : primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['title'] ?? 'Notifikasi',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: onSurfaceColor.withValues(
                                            alpha: isRead ? 0.8 : 1.0,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textTertiary.withValues(
                                      alpha: isRead ? 0.8 : 1.0,
                                    ),
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notif['created_at'] ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: textTertiary.withValues(
                                      alpha: isRead ? 0.8 : 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 400.ms, delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
                },
              ),
      ),
    );
  }
}
