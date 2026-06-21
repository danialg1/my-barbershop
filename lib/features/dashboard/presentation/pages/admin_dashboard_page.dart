import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFD4AF37); // Gold

  late TabController _tabController;

  int _currentIndex = 0;
  bool _isLoading = true;

  // Stats Data
  int _totalIncome = 0;
  int _totalCustomers = 0;
  int _totalBarbers = 0;

  // Data Lists
  List<dynamic> _reservations = [];
  List<dynamic> _servicesList = [];
  List<dynamic> _barbersList = [];
  List<dynamic> _customersList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCache();
    _fetchAllData();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedServices = prefs.getString('cached_services');
    if (cachedServices != null) {
      if (mounted) {
        setState(() {
          _servicesList = jsonDecode(cachedServices);
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch Stats
      final statsRes = await http.get(
        Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_admin_stats.php'),
      );
      if (statsRes.statusCode == 200) {
        final statsJson = jsonDecode(statsRes.body);
        if (statsJson['status'] == 'success') {
          final data = statsJson['data'];
          _totalIncome = data['total_income'] ?? 0;
          _totalCustomers = data['total_customers'] ?? 0;
          _totalBarbers = data['total_barbers'] ?? 0;
        }
      }

      // 2. Fetch Reservations
      final resRes = await http.get(
        Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_all_reservations.php'),
      );
      if (resRes.statusCode == 200) {
        final resJson = jsonDecode(resRes.body);
        if (resJson['status'] == 'success') {
          _reservations = resJson['data'] ?? [];
        }
      }

      // 3. Fetch Services
      final srvRes = await http.post(
        Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/admin_crud_services.php'),
        body: jsonEncode({'action': 'read'}),
      );
      if (srvRes.statusCode == 200) {
        final srvJson = jsonDecode(srvRes.body);
        if (srvJson['status'] == 'success') {
          _servicesList = srvJson['data'] ?? [];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_services', jsonEncode(_servicesList));
        }
      }

      // 4. Fetch Barbers
      final barRes = await http.post(
        Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/admin_crud_users.php'),
        body: jsonEncode({'action': 'read', 'role': 'barber'}),
      );
      if (barRes.statusCode == 200) {
        final barJson = jsonDecode(barRes.body);
        if (barJson['status'] == 'success') {
          _barbersList = barJson['data'] ?? [];
        }
      }

      // 5. Fetch Customers
      final cusRes = await http.post(
        Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/admin_crud_users.php'),
        body: jsonEncode({'action': 'read', 'role': 'customer'}),
      );
      if (cusRes.statusCode == 200) {
        final cusJson = jsonDecode(cusRes.body);
        if (cusJson['status'] == 'success') {
          _customersList = cusJson['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'canceled':
      case 'cancelled':
        return Colors.red;
      case 'cancel_requested':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'in_progress':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      case 'canceled':
      case 'cancelled':
        return 'Dibatalkan';
      case 'cancel_requested':
        return 'Minta Batal';
      default:
        return status.toUpperCase();
    }
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
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

    final List<Widget> pages = [
      _buildHomeTab(bgColor, surfaceColor, onSurfaceColor, textTertiary),
      _buildServicesTab(bgColor, surfaceColor, onSurfaceColor, textTertiary),
      _buildUsersTab(bgColor, surfaceColor, onSurfaceColor, textTertiary),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.room_service),
            label: 'Layanan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Pengguna'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(
    Color bgColor,
    Color surfaceColor,
    Color onSurfaceColor,
    Color textTertiary,
  ) {
    final recentReservations = _reservations.take(5).toList();

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Admin',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ringkasan Sistem Hari Ini',
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.logout, color: textTertiary),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ilustrasi Interaktif
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.8),
                          primaryColor.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                        ),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black45,
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Kelola Bisnis Anda\nDengan Elegan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Column(
              children: [
                _buildStatCard(
                  title: 'Total Pendapatan',
                  value: _formatCurrency(_totalIncome),
                  icon: Icons.account_balance_wallet,
                  surfaceColor: surfaceColor,
                  onSurfaceColor: onSurfaceColor,
                  textTertiary: textTertiary,
                  isPrimary: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Pelanggan',
                        value: '$_totalCustomers',
                        icon: Icons.groups,
                        surfaceColor: surfaceColor,
                        onSurfaceColor: onSurfaceColor,
                        textTertiary: textTertiary,
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Barber',
                        value: '$_totalBarbers',
                        icon: Icons.content_cut,
                        surfaceColor: surfaceColor,
                        onSurfaceColor: onSurfaceColor,
                        textTertiary: textTertiary,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Terbaru',
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (recentReservations.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Belum ada transaksi',
                        style: TextStyle(color: textTertiary),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentReservations.length,
                    itemBuilder: (context, index) {
                      final res = recentReservations[index];
                      return _buildTransactionItem(
                        res,
                        surfaceColor,
                        onSurfaceColor,
                        textTertiary,
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // --- LAYANAN TAB ---
  Widget _buildServicesTab(
    Color bgColor,
    Color surfaceColor,
    Color onSurfaceColor,
    Color textTertiary,
  ) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Manajemen Layanan',
          style: TextStyle(color: onSurfaceColor),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: _servicesList.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 400,
                          child: Center(
                            child: Text(
                              'Tidak ada layanan',
                              style: TextStyle(color: textTertiary),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _servicesList.length,
                      itemBuilder: (context, index) {
                        final srv = _servicesList[index];
                        return Card(
                          color: surfaceColor,
                          elevation: 2,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showServiceDialog(srv),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: srv['image_url'] != null
                                        ? Image.network(
                                            srv['image_url'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.room_service, color: primaryColor, size: 32),
                                          )
                                        : Icon(Icons.room_service, color: primaryColor, size: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          srv['name'],
                                          style: TextStyle(
                                            color: onSurfaceColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(int.tryParse(srv['price'].toString()) ?? 0),
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showServiceDialog(srv),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteService(srv['id']),
                                        tooltip: 'Hapus',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showServiceDialog(null),
      ),
    );
  }

  // --- PENGGUNA TAB (TAB BAR) ---
  Widget _buildUsersTab(
    Color bgColor,
    Color surfaceColor,
    Color onSurfaceColor,
    Color textTertiary,
  ) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Manajemen Pengguna',
          style: TextStyle(color: onSurfaceColor),
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textTertiary,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Barber'),
            Tab(text: 'Pelanggan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(
            _barbersList,
            'barber',
            surfaceColor,
            onSurfaceColor,
            textTertiary,
          ),
          _buildUserList(
            _customersList,
            'customer',
            surfaceColor,
            onSurfaceColor,
            textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    List<dynamic> list,
    String role,
    Color surfaceColor,
    Color onSurfaceColor,
    Color textTertiary,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 400,
                          child: Center(
                            child: Text(
                              'Tidak ada $role',
                              style: TextStyle(color: textTertiary),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final usr = list[index];
                        final String photoBase64 = usr['photo'] ?? '';
                        Widget avatarWidget;
                        if (photoBase64.isNotEmpty &&
                            photoBase64.length > 100) {
                          avatarWidget = CircleAvatar(
                            backgroundImage: MemoryImage(
                              base64Decode(photoBase64),
                            ),
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.2,
                            ),
                          );
                        } else {
                          avatarWidget = CircleAvatar(
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(Icons.person, color: primaryColor),
                          );
                        }

                        return Card(
                          color: surfaceColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: avatarWidget,
                            title: Text(
                              usr['name'],
                              style: TextStyle(
                                color: onSurfaceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              usr['email'],
                              style: TextStyle(color: textTertiary),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showUserDialog(usr, role),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(usr['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showUserDialog(null, role),
      ),
    );
  }

  // --- ACTION MODALS (SERVICES) ---
  void _showServiceDialog(dynamic service) {
    final isEdit = service != null;
    final nameCtrl = TextEditingController(text: isEdit ? service['name'] : '');
    final descCtrl = TextEditingController(
      text: isEdit ? service['description'] : '',
    );
    final priceCtrl = TextEditingController(
      text: isEdit ? service['price'].toString() : '',
    );

    String? base64Image;
    String? existingImageUrl = isEdit ? service['image_url'] : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Layanan' : 'Tambah Layanan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          final CroppedFile? croppedFile = await ImageCropper().cropImage(
                            sourcePath: image.path,
                            uiSettings: [
                              AndroidUiSettings(
                                toolbarTitle: 'Potong Foto Layanan',
                                toolbarColor: primaryColor,
                                toolbarWidgetColor: Colors.white,
                                initAspectRatio: CropAspectRatioPreset.square,
                                lockAspectRatio: true,
                              ),
                              IOSUiSettings(
                                title: 'Potong Foto Layanan',
                                aspectRatioLockEnabled: true,
                              ),
                            ],
                          );
                          if (croppedFile != null) {
                            final bytes = await croppedFile.readAsBytes();
                            setStateDialog(() {
                              base64Image = base64Encode(bytes);
                            });
                          }
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: base64Image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(base64Image!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (existingImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        existingImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          color: primaryColor,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Pilih Gambar',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Layanan',
                      ),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                    ),
                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Harga'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await http.post(
                      Uri.parse(
                        'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/admin_crud_services.php',
                      ),
                      body: jsonEncode({
                        'action': isEdit ? 'update' : 'create',
                        'id': isEdit ? service['id'] : null,
                        'name': nameCtrl.text,
                        'description': descCtrl.text,
                        'price': priceCtrl.text,
                        'image_base64': base64Image,
                      }),
                    );
                    _fetchAllData();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteService(String id) async {
    await http.post(
      Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/admin_crud_services.php'),
      body: jsonEncode({'action': 'delete', 'id': id}),
    );
    _fetchAllData();
  }

  // --- ACTION MODALS (USERS) ---
  void _showUserDialog(dynamic user, String role) {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: isEdit ? user['name'] : '');
    final emailCtrl = TextEditingController(text: isEdit ? user['email'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? user['phone'] : '');
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit $role' : 'Tambah $role'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                ),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Password (Opsional)' : 'Password',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await http.post(
                  Uri.parse(
                    'https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/admin_crud_users.php',
                  ),
                  body: jsonEncode({
                    'action': isEdit ? 'update' : 'create',
                    'id': isEdit ? user['id'] : null,
                    'role': role,
                    'name': nameCtrl.text,
                    'email': emailCtrl.text,
                    'phone': phoneCtrl.text,
                    'password': passCtrl.text,
                  }),
                );
                _fetchAllData();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(String id) async {
    await http.post(
      Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/admin_crud_users.php'),
      body: jsonEncode({'action': 'delete', 'id': id}),
    );
    _fetchAllData();
  }

  // --- HELPER WIDGETS ---
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required Color textTertiary,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: isPrimary ? 0.5 : 0.2),
        ),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: isPrimary ? primaryColor : onSurfaceColor,
              fontSize: isPrimary ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    dynamic res,
    Color surfaceColor,
    Color onSurfaceColor,
    Color textTertiary,
  ) {
    final status = res['status'] ?? 'pending';
    final price = int.tryParse(res['service_price']?.toString() ?? '0') ?? 0;

    String dateStr = res['reservation_date'] ?? '';
    try {
      if (dateStr.length >= 16) {
        final date = DateTime.parse(dateStr);
        dateStr =
            '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.person, color: textTertiary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        res['customer_name'] ?? 'Unknown',
                        style: TextStyle(
                          color: onSurfaceColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.sync_alt, size: 16, color: Colors.grey),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.content_cut, color: primaryColor, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        res['barber_name'] ?? 'Any Barber',
                        style: TextStyle(
                          color: onSurfaceColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(color: textTertiary, fontSize: 11),
                  ),
                ],
              ),
              Text(
                _formatCurrency(price),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (status == 'cancel_requested') ...[
            const SizedBox(height: 12),
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
                    'Alasan Pembatalan:',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    res['cancel_reason'] ?? '-',
                    style: TextStyle(color: onSurfaceColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleCancelRequest(
                      res['reservation_id'].toString(),
                      'reject_cancel',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Tolak Batal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleCancelRequest(
                      res['reservation_id'].toString(),
                      'approve_cancel',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Terima Batal',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleCancelRequest(String reservationId, String action) async {
    try {
      await http.post(
        Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/update_reservation.php'),
        body: jsonEncode({'reservation_id': reservationId, 'action': action}),
      );
      _fetchAllData();
    } catch (e) {
      // ignore
    }
  }
}
