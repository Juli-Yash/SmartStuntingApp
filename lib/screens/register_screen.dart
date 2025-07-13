// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';
import 'login_screen.dart'; // Import LoginScreen untuk navigasi kembali

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  final AuthService _authService = AuthService();
  String _message = '';
  bool _isError = false;

  void _register() async {
    setState(() {
      _message = '';
      _isError = false;
    });

    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmationController.text.isEmpty) {
      setState(() {
        _message = 'Semua kolom harus diisi.';
        _isError = true;
      });
      return;
    }

    if (_passwordController.text != _passwordConfirmationController.text) {
      setState(() {
        _message = 'Konfirmasi kata sandi tidak cocok.';
        _isError = true;
      });
      return;
    }

    try {
      AuthResponse response = await _authService.register(
        _nameController.text,
        _phoneController.text,
        _passwordController.text,
        _passwordConfirmationController.text,
      );

      if (response.accessToken != null) {
        setState(() {
          _message = response.message ?? 'Registrasi Berhasil!';
          _isError = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message)));
        print('Registrasi Berhasil! Access Token: ${response.accessToken}');

        // KEMBALI KE HALAMAN LOGIN SETELAH REGISTRASI SUKSES
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        setState(() {
          _message =
              response.message ??
              'Registrasi gagal. Terjadi kesalahan tidak dikenal.';
          _isError = true;
          if (response.errors != null && response.errors!.isNotEmpty) {
            response.errors!.forEach((key, value) {
              _message += '\n${key}: ${value.join(', ')}';
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Terjadi kesalahan jaringan: $e';
        _isError = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Smart Stunting'),
        centerTitle: true,
        backgroundColor: Colors.blue, // Warna biru
        foregroundColor: Colors.white, // Teks dan ikon putih
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Teks biru
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama Anda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Colors.blue,
                  ), // Ikon biru
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  hintText: 'Contoh: 081234567890',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(
                    Icons.phone,
                    color: Colors.blue,
                  ), // Ikon biru
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  hintText: 'Buat kata sandi Anda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: Colors.blue,
                  ), // Ikon biru
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordConfirmationController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi',
                  hintText: 'Ulangi kata sandi Anda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_reset,
                    color: Colors.blue,
                  ), // Ikon biru
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _isError
                          ? Colors.red
                          : Colors.blue, // Pesan sukses biru
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Tombol biru
                  foregroundColor: Colors.white, // Teks tombol putih
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'DAFTAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Sudah punya akun? Login di sini',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ), // Teks biru
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
