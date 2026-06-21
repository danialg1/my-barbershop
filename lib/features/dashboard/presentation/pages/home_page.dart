import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../reservation/presentation/pages/reservation_form_page.dart';
import '../../../../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'Memuat...';
  String _photoBase64 = '';
  List<dynamic> _servicesList = [];
  bool _isLoadingServices = true;
  List<dynamic> _barbersList = [];
  bool _isLoadingBarbers = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchServices();
    _fetchBarbers();
    profileUpdateNotifier.addListener(_loadUserData);
  }

  Future<void> _fetchBarbers() async {
    try {
      final response = await http.get(
        Uri.parse('https://aleen-pseudoanaphylactic-bewailingly.ngrok-free.dev/barbershop_api/get_active_barbers.php'),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (mounted) {
            setState(() {
              _barbersList = jsonResponse['data'] ?? [];
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

  @override
  void dispose() {
    profileUpdateNotifier.removeListener(_loadUserData);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    String namaFallback = 'Pengguna';
    try {
      final prefs = await SharedPreferences.getInstance();
      namaFallback = prefs.getString('user_name') ?? 'Pengguna';
      final userId = prefs.getString('user_id');

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
                _userName = data['name'] ?? namaFallback;
                _photoBase64 = data['photo'] ?? '';
              });
            }
          }
        }
      } else {
        // Fallback jika tidak ada user_id
        if (!mounted) return;
        setState(() {
          _userName = namaFallback;
          _photoBase64 = '';
        });
      }
    } catch (e) {
      debugPrint('Error ambil data: $e');
      if (!mounted) return;
      setState(() {
        _userName = namaFallback;
      });
    }
  }

  // Palet Warna Sesuai Desain Stitch
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildPromoBanner(),
                    const SizedBox(height: 32),
                    _buildLayananKami(),
                    const SizedBox(height: 32),
                    _buildBarberTersedia(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET MODULAR ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: bgColor,
      child: Row(
        children: [
          (_photoBase64.isNotEmpty && _photoBase64.length > 100)
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: outlineColor),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(_photoBase64)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: outlineColor),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 24,
                    color: Color(0xFF94A3B8),
                  ),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Halo, $_userName',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: onSurfaceColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: outlineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari layanan atau barber...',
          hintStyle: TextStyle(color: textTertiary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 128,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?q=80&w=2074&auto=format&fit=crop',
          ), // Placeholder Barbershop
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.3),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Diskon 20% Potong\nRambut Pertama',
              style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan kode: BARBER20',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayananKami() {
    final filteredServices = _servicesList.where((s) {
      final name = s['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Layanan Kami',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onSurfaceColor,
              ),
            ),
            Text(
              'Lihat Semua',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingServices)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filteredServices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Tidak ada layanan yang sesuai',
                style: TextStyle(color: textTertiary),
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReservationFormPage(
                          initialServiceId: service['id'].toString(),
                          initialServiceName: service['name'].toString(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: outlineColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                service['image_url']?.toString() ??
                                    'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?q=80&w=200&auto=format&fit=crop',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: bgColor,
                                  child: Icon(Icons.room_service,
                                      color: textTertiary, size: 40),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['name']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: onSurfaceColor,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    service['description']?.toString() ??
                                        'Layanan pangkas rambut terbaik dan profesional.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textTertiary,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rp ${service['price']}',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: primaryColor,
                                        size: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
      ],
    );
  }

  Widget _buildBarberTersedia() {
    final filteredBarbers = _barbersList.where((b) {
      final name = b['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barber Tersedia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingBarbers)
          const Center(child: CircularProgressIndicator())
        else if (filteredBarbers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Tidak ada barber yang sesuai',
                style: TextStyle(color: textTertiary),
              ),
            ),
          )
        else
          SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredBarbers.length,
              itemBuilder: (context, index) {
                final barber = filteredBarbers[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outlineColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Image.network(
                          barber['image'] ?? 'https://picsum.photos/200',
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 140,
                                color: bgColor,
                                child: const Icon(Icons.person, size: 50),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              barber['name'] ?? 'Barber',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              barber['role'] ?? 'Professional Barber',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  barber['exp'] ?? 'Tersedia',
                                  style: TextStyle(
                                    color: textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReservationFormPage(
                                          initialBarberId: barber['id'].toString(),
                                          initialBarberName: barber['name'].toString(),
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('Pilih'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
