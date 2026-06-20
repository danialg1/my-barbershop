import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../main.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Variabel untuk menyimpan foto yang dipilih
  XFile? _pickedImage;
  String _currentPhotoBase64 = '';
  bool _isLoading = true;
  bool _isPickingImage = false;
  bool _photoDeleted = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null && userId.isNotEmpty) {
        final url = Uri.parse(
          'http://192.168.1.5/barbershop_api/get_profile.php',
        );
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId}),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['status'] == 'success') {
            final data = jsonResponse['data'];
            if (data != null) {
              setState(() {
                _nameController.text = data['name'] ?? '';
                _emailController.text = data['email'] ?? '';
                _phoneController.text = data['phone'] ?? '';
                _currentPhotoBase64 = data['photo'] ?? '';
              });
            }
          } else {
            if (!mounted) return;
            SnackbarUtils.showError(
              context,
              jsonResponse['message'] ?? 'Gagal mengambil data profil.',
            );
          }
        } else {
          if (!mounted) return;
          SnackbarUtils.showError(context, 'Terjadi kesalahan pada server.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Gagal memuat data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- LOGIKA GANTI FOTO (TODO 1 SELESAI) ---
  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // HD Quality
      );

      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressQuality: 100, // No compression
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Potong Foto',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _pickedImage = XFile(croppedFile.path);
            _photoDeleted = false; // Batal menghapus karena milih foto baru
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  // --- LOGIKA UPDATE REST API ---
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null && userId.isNotEmpty) {
        final updateData = <String, dynamic>{
          'user_id': userId,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        };

        if (_pickedImage != null) {
          final imageBytes = await _pickedImage!.readAsBytes();
          updateData['photoBase64'] = base64Encode(imageBytes);
        } else if (_photoDeleted) {
          updateData['photoBase64'] = ''; // Kirim string kosong untuk menghapus foto di database
        }

        final url = Uri.parse(
          'http://192.168.1.5/barbershop_api/update_profile.php',
        );
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updateData),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['status'] == 'success') {
            // Update nama di SharedPreferences juga
            await prefs.setString('user_name', _nameController.text.trim());
            profileUpdateNotifier.value++;

            if (!mounted) return;
            SnackbarUtils.showSuccess(
              context,
              jsonResponse['message'] ?? 'Perubahan berhasil disimpan!',
            );
            Navigator.pop(context);
          } else {
            SnackbarUtils.showError(
              context,
              jsonResponse['message'] ?? 'Gagal menyimpan profil.',
            );
          }
        } else {
          SnackbarUtils.showError(context, 'Terjadi kesalahan pada server.');
        }
      } else {
        if (!mounted) return;
        SnackbarUtils.showError(context, 'Sesi tidak ditemukan.');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Gagal menyimpan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor.withValues(alpha: 0.8),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _buildProfilePicture(),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline,
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Email',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Nomor Telepon',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveProfile,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
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

  Widget _buildProfilePicture() {
    Widget imageWidget;
    
    if (_pickedImage != null) {
      imageWidget = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: outlineColor, width: 4),
          image: DecorationImage(
            image: kIsWeb ? NetworkImage(_pickedImage!.path) as ImageProvider : FileImage(File(_pickedImage!.path)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (!_photoDeleted && _currentPhotoBase64.isNotEmpty && _currentPhotoBase64.length > 100) {
      imageWidget = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: outlineColor, width: 4),
          image: DecorationImage(
            image: MemoryImage(base64Decode(_currentPhotoBase64)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      imageWidget = Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
          border: Border.all(color: outlineColor, width: 4),
        ),
        child: const Icon(
          Icons.person,
          size: 80,
          color: Color(0xFF94A3B8),
        ),
      );
    }

    return Center(
      child: Stack(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: imageWidget,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pickedImage != null || (!_photoDeleted && _currentPhotoBase64.isNotEmpty && _currentPhotoBase64.length > 100))
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                      onPressed: () {
                        setState(() {
                          _pickedImage = null;
                          _photoDeleted = true;
                        });
                      },
                    ),
                  ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB45309),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14, color: onSurfaceColor),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: textTertiary, size: 20),
            filled: true,
            fillColor: bgColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: outlineColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
