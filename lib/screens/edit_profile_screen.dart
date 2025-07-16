// lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/user.dart';
import 'package:smart_stunting_app/services/auth_service.dart';
import 'package:smart_stunting_app/models/auth_response.dart'; // Untuk menangani response API

class EditProfileScreen extends StatefulWidget {
  final User user; // Menerima data user yang akan diedit

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (!_formKey.currentState!.validate()) {
      // Jika validasi form dasar gagal
      return;
    }

    // Validasi tambahan untuk password jika diisi
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text.length < 8) {
        setState(() {
          _errorMessage = 'Kata sandi minimal 8 karakter.';
        });
        return;
      }
      if (_passwordController.text != _passwordConfirmationController.text) {
        setState(() {
          _errorMessage = 'Konfirmasi kata sandi tidak cocok.';
        });
        return;
      }
    } else {
      // Jika password kosong, pastikan konfirmasi password juga kosong
      if (_passwordConfirmationController.text.isNotEmpty) {
        setState(() {
          _errorMessage =
              'Konfirmasi kata sandi harus kosong jika kata sandi baru kosong.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      AuthResponse response = await _authService.updateUserProfile(
        _nameController.text,
        _phoneController.text,
        _passwordController.text.isEmpty
            ? null
            : _passwordController.text, // Kirim null jika kosong
        _passwordConfirmationController.text.isEmpty
            ? null
            : _passwordConfirmationController.text, // Kirim null jika kosong
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Periksa 'success' property dari AuthResponse atau asumsi berdasarkan message/errors
      if (response.message != null &&
          (response.errors == null || response.errors!.isEmpty)) {
        setState(() {
          _successMessage = response.message!;
          _errorMessage = ''; // Hapus pesan error sebelumnya
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage),
            backgroundColor: Colors.green,
          ),
        );
        // Kosongkan password fields setelah berhasil update
        _passwordController.clear();
        _passwordConfirmationController.clear();
        // Kembali ke ProfileTab dan beritahu untuk refresh data
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Mengirimkan 'true' sebagai hasil dari pop untuk menandakan update berhasil
        }
      } else if (response.errors != null && response.errors!.isNotEmpty) {
        // Error validasi dari server
        setState(() {
          _errorMessage = 'Gagal memperbarui profil:';
          response.errors!.forEach((key, value) {
            _errorMessage +=
                '\n${value.join(', ')}'; // Tampilkan hanya pesan error, bukan nama field
          });
          _successMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
      } else {
        // Error umum atau pesan error lainnya dari server
        setState(() {
          _errorMessage =
              response.message ??
              'Terjadi kesalahan tidak dikenal saat memperbarui profil.';
          _successMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan jaringan: $e';
          _successMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ubah Informasi Akun Anda',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  'Ubah Kata Sandi (Kosongkan jika tidak ingin mengubah)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Baru',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                  ),
                  obscureText: true,
                  // Validator di sini hanya untuk panjang, validasi kecocokan di _updateProfile
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 8) {
                      return 'Kata sandi minimal 8 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordConfirmationController,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi Baru',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_reset,
                      color: Colors.blue,
                    ),
                  ),
                  obscureText: true,
                  // Validator di sini hanya untuk keberadaan jika password baru diisi
                  validator: (value) {
                    if (_passwordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return 'Konfirmasi kata sandi harus diisi.';
                    }
                    return null; // Validasi kecocokan sudah di _updateProfile
                  },
                ),
                const SizedBox(height: 30),
                // Tidak perlu menampilkan _errorMessage dan _successMessage terpisah di sini
                // Cukup gunakan SnackBar
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
                    : ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
