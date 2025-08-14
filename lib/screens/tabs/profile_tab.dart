// lib/screens/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/user.dart';
import 'package:smart_stunting_app/services/auth_service.dart';
import 'package:smart_stunting_app/screens/login_screen.dart';
import 'package:smart_stunting_app/screens/edit_profile_screen.dart';

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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final user = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Unauthorized') ||
            e.toString().contains('Invalid token')) {
          await _authService.logout(); // Bersihkan token lokal
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          setState(() {
            _errorMessage =
                'Gagal memuat profil: ${e.toString().replaceFirst('Exception: ', '')}';
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = '';
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
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal logout: ${e.toString().replaceFirst('Exception: ', '')}';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _navigateToEditProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil belum dimuat. Mohon tunggu atau coba refresh.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final User? updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    );

    if (updatedUser != null) {
      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
        });

        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchUserProfile,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 50.0,
                bottom: 20.0,
                left: 16.0,
                right: 16.0,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                // Changed from const BoxDecoration
                color: Colors.blue,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blueAccent[700],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _currentUser?.name ?? 'Memuat Nama...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentUser?.email ?? 'Memuat Email...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    )
                  : _errorMessage.isNotEmpty
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
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _fetchUserProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 5,
                            color: Colors.white,
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
                                    Icons.person_outline,
                                    'Nama Lengkap',
                                    _currentUser?.name ?? 'Tidak tersedia',
                                  ),
                                  const Divider(height: 25, thickness: 1),
                                  _buildProfileInfoRow(
                                    Icons.email_outlined,
                                    'Email',
                                    _currentUser?.email ?? 'Tidak tersedia',
                                  ),
                                  const Divider(height: 25, thickness: 1),
                                  _buildProfileInfoRow(
                                    Icons.phone_outlined,
                                    'Nomor Telepon',
                                    _currentUser?.phone ?? 'Tidak tersedia',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          ElevatedButton(
                            onPressed: _navigateToEditProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
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
                          // Tombol Logout
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[700], size: 24),
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
                    fontWeight: FontWeight.bold,
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
