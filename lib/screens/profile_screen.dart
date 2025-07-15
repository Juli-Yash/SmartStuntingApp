// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/user.dart';
import 'package:smart_stunting_app/services/auth_service.dart';
import 'package:smart_stunting_app/screens/login_screen.dart'; // Untuk navigasi setelah logout
import 'package:smart_stunting_app/models/auth_response.dart'; // Untuk respon update profile

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated; // Callback untuk memberitahu HomeScreen
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  String _errorMessage = '';

  // Controllers untuk edit profile
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isEditing = false; // State untuk mode edit

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final user = await _authService.fetchUserProfile();
      setState(() {
        _currentUser = user;
        if (_currentUser != null) {
          _nameController.text = _currentUser!.name;
          _phoneController.text = _currentUser!.phoneNumber;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat profil: ${e.toString()}';
      });
      // Jika terjadi error saat fetch (misal token expired), paksa logout
      // Pastikan context masih valid sebelum navigasi
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

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Konfirmasi password tidak cocok.';
        _isLoading = false;
      });
      return;
    }

    try {
      final AuthResponse response = await _authService.updateUserProfile(
        _nameController.text,
        _phoneController.text,
        _passwordController.text.isNotEmpty ? _passwordController.text : null,
        _confirmPasswordController.text.isNotEmpty
            ? _confirmPasswordController.text
            : null,
      );

      if (response.message != null && response.accessToken == null) {
        setState(() {
          _errorMessage = ''; // Clear any previous error
          _isEditing = false; // Keluar dari mode edit
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message!),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchUserProfile(); // Refresh data profil setelah update
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!(); // Panggil callback ke HomeScreen
        }
      } else if (response.errors != null && response.errors!.isNotEmpty) {
        setState(() {
          _errorMessage = 'Gagal memperbarui profil:';
          response.errors!.forEach((key, value) {
            _errorMessage += '\n$key: ${value.join(', ')}';
          });
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Terjadi kesalahan tidak dikenal.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
          _errorMessage = 'Gagal logout: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar dihapus sesuai permintaan
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
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
                    onPressed: () {
                      setState(() {
                        _isEditing = true; // Masuk mode edit
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
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
                  const SizedBox(height: 20),

                  // Bagian Edit Profil (muncul saat _isEditing adalah true)
                  if (_isEditing) ...[
                    const Divider(
                      height: 40,
                      thickness: 1,
                      color: Colors.blueGrey,
                    ),
                    Text(
                      'Edit Detail Profil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password Baru (opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_open,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green, // Warna berbeda untuk simpan
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'SIMPAN PERUBAHAN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Spasi setelah tombol simpan
                  ],

                  // Tombol Logout (IconButton) di bagian bawah
                  Align(
                    alignment: Alignment.center, // Pusatkan ikon logout
                    child: IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 40,
                      ),
                      onPressed: _logout,
                      tooltip: 'Logout', // Tooltip saat di-hover
                    ),
                  ),
                  const SizedBox(height: 20), // Spasi di bagian paling bawah
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
