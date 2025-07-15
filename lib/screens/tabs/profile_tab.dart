// lib/screens/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/user.dart';
import 'package:smart_stunting_app/services/auth_service.dart';
import 'package:smart_stunting_app/screens/login_screen.dart';
// import 'package:smart_stunting_app/models/auth_response.dart'; // DIHAPUS: Unused import
import 'package:smart_stunting_app/screens/edit_profile_screen.dart'; // Import EditProfileScreen

class ProfileTab extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileTab({super.key, this.onProfileUpdated});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  String _errorMessage =
      ''; // Akan digunakan untuk menampilkan error fetch/logout

  // Controllers untuk edit profile tidak lagi diperlukan di sini
  // final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _phoneController = TextEditingController();
  // final TextEditingController _passwordController = TextEditingController();
  // final TextEditingController _confirmPasswordController = TextEditingController();

  // bool _isEditing = false; // State ini tidak lagi diperlukan di sini

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    // Pastikan tidak ada controller yang di-dispose jika tidak dideklarasikan di sini
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Reset error message
    });
    try {
      final user = await _authService.fetchUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal memuat profil: ${e.toString().replaceFirst('Exception: ', '')}';
      });
      // Jika terjadi error saat fetch (misal token expired), paksa logout
      if (mounted) {
        await _authService.logout();
        if (mounted) {
          // Check mounted again after async operation
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Metode _updateProfile dihapus karena sudah dipindahkan ke EditProfileScreen

  Future<void> _logout() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = ''; // Reset error message
      });
      try {
        await _authService.logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage =
              'Gagal logout: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk menavigasi ke EditProfileScreen
  void _navigateToEditProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil belum dimuat. Mohon tunggu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? profileUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    );

    // Jika kembali dari EditProfileScreen dan ada indikasi update, refresh data
    if (profileUpdated == true) {
      await _fetchUserProfile(); // Refresh data profil
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!(); // Panggil callback ke HomeScreen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Signature method build
    return Scaffold(
      // AppBar dihapus sepenuhnya sesuai permintaan
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _errorMessage
                .isNotEmpty // MENAMPILKAN ERROR MESSAGE
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchUserProfile, // Coba lagi fetch profil
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Person di bagian atas
                  const Icon(
                    Icons
                        .person_pin, // Atau Icons.account_circle, Icons.person_outline
                    size: 100,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Profil Pengguna',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Card Informasi Detail Profil
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileInfoRow(
                            Icons.person,
                            'Nama Lengkap',
                            _currentUser?.name ?? 'Memuat...',
                          ),
                          const Divider(height: 25, thickness: 1),
                          _buildProfileInfoRow(
                            Icons.phone,
                            'Nomor Telepon',
                            _currentUser?.phoneNumber ?? 'Memuat...',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Tombol Edit Profil
                  ElevatedButton(
                    onPressed:
                        _navigateToEditProfile, // Memanggil fungsi navigasi
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'EDIT PROFIL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), // Spasi sebelum ikon logout
                  // Tombol Logout (IconButton) di bagian bawah
                  Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 40,
                      ),
                      onPressed: _logout,
                      tooltip: 'Logout',
                    ),
                  ),
                  const SizedBox(height: 20), // Spasi di paling bawah
                ],
              ),
            ),
    );
  }

  // Helper Widget untuk baris info profil
  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.blueGrey[700]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
