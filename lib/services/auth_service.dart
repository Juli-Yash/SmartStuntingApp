// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthService {
  final String _baseUrl = 'http://147.93.106.201/api';

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove(
      'user_id',
    ); // <<< TAMBAHKAN: Hapus juga user_id saat logout
  }

  // --- START PERBAIKAN: Tambahkan metode untuk User ID ---
  Future<void> _saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }
  // --- END PERBAIKAN ---

  // Helper untuk mendapatkan header dengan token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      // Jika token tidak ada, anggap tidak terautentikasi dan throw error
      throw Exception('Token not found. User is not authenticated.');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- Metode untuk proses Login ---
  Future<AuthResponse> login(String phone, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phone_number': phone, 'password': password}),
      );

      final responseBody = jsonDecode(response.body);
      print(
        'Login API Response: $responseBody (Status: ${response.statusCode})',
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(responseBody);
        if (authResponse.accessToken != null) {
          await _saveToken(authResponse.accessToken!);
          // --- PERBAIKAN: Setelah login berhasil, ambil profil dan simpan user_id ---
          final userProfile =
              await fetchUserProfile(); // Ini akan memanggil fetchUserProfile yang sudah diperbarui
          if (userProfile != null) {
            await _saveUserId(userProfile.id); // Simpan ID pengguna
          }
          // --- END PERBAIKAN ---
        }
        return authResponse;
      } else {
        return AuthResponse.fromJson(responseBody);
      }
    } catch (e) {
      print('Error during login: $e');
      return AuthResponse(
        message: 'Terjadi kesalahan jaringan atau server tidak merespons.',
      );
    }
  }

  // --- Metode untuk proses Registrasi ---
  Future<AuthResponse> register(
    String name,
    String phone,
    String password,
    String passwordConfirmation,
  ) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'phone_number': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final responseBody = jsonDecode(response.body);
      print(
        'Register API Response: $responseBody (Status: ${response.statusCode})',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(responseBody);
        if (authResponse.accessToken != null) {
          await _saveToken(authResponse.accessToken!);
          // --- PERBAIKAN: Setelah register berhasil, ambil profil dan simpan user_id ---
          final userProfile = await fetchUserProfile();
          if (userProfile != null) {
            await _saveUserId(userProfile.id); // Simpan ID pengguna
          }
          // --- END PERBAIKAN ---
        }
        return authResponse;
      } else {
        return AuthResponse.fromJson(responseBody);
      }
    } catch (e) {
      print('Error during registration: $e');
      return AuthResponse(
        message: 'Terjadi kesalahan jaringan atau server tidak merespons.',
      );
    }
  }

  // --- Metode untuk proses Logout ---
  Future<AuthResponse> logout() async {
    final url = Uri.parse('$_baseUrl/logout');
    try {
      // Try to get headers even if token might be invalid to attempt logout from server
      // If _getAuthHeaders throws due to missing token, it means we're already logged out locally.
      Map<String, String>? headers;
      try {
        headers = await _getAuthHeaders();
      } catch (e) {
        print(
          'No token to send for server logout, proceeding with local logout.',
        );
      }

      http.Response response;
      if (headers != null) {
        response = await http.post(url, headers: headers);
        final responseBody = jsonDecode(response.body);
        print(
          'Logout API Response: $responseBody (Status: ${response.statusCode})',
        );
      } else {
        response = http.Response(
          '{"message": "Logged out locally due to missing token."}',
          200,
        );
      }

      await _removeToken(); // Selalu hapus token dan user_id lokal
      return AuthResponse(message: 'Berhasil logout.');
    } catch (e) {
      print('Error during logout: $e');
      await _removeToken(); // Pastikan token tetap dihapus walaupun ada error jaringan
      return AuthResponse(message: 'Terjadi kesalahan jaringan saat logout.');
    }
  }

  // Metode untuk mengambil data profil pengguna
  Future<User?> fetchUserProfile() async {
    final url = Uri.parse('$_baseUrl/profile');
    try {
      final headers =
          await _getAuthHeaders(); // Ini akan throw exception jika token tidak ada
      final response = await http.get(url, headers: headers);

      final responseBody = jsonDecode(response.body);
      print(
        'Fetch Profile API Response: $responseBody (Status: ${response.statusCode})',
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(responseBody);
        // --- PERBAIKAN: Simpan ID pengguna yang baru diambil ---
        await _saveUserId(user.id);
        // --- END PERBAIKAN ---
        return user;
      } else if (response.statusCode == 401) {
        // Token tidak valid/expired, paksa logout
        await _removeToken();
        print('Token expired/invalid, forcing logout.');
        return null;
      } else {
        print('Failed to fetch profile: ${responseBody['message']}');
        return null;
      }
    } catch (e) {
      print('Error fetching profile: $e');
      await _removeToken(); // Asumsi jika ada error di _getAuthHeaders atau fetch, user perlu logout
      return null;
    }
  }

  // Metode untuk memperbarui data profil pengguna
  Future<AuthResponse> updateUserProfile(
    String name,
    String phoneNumber,
    String? password,
    String? passwordConfirmation,
  ) async {
    final url = Uri.parse('$_baseUrl/profile');
    Map<String, dynamic> body = {'name': name, 'phone_number': phoneNumber};
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation;
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body);
      print(
        'Update Profile API Response: $responseBody (Status: ${response.statusCode})',
      );

      if (response.statusCode == 200) {
        // Setelah update profil, kemungkinan nama/phone berubah,
        // tapi ID tetap sama, jadi tidak perlu save user_id lagi.
        // Cukup pastikan data di UI di-refresh (sudah dilakukan di ProfileTab)
        return AuthResponse.fromJson(responseBody);
      } else {
        return AuthResponse.fromJson(responseBody);
      }
    } catch (e) {
      print('Error updating profile: $e');
      return AuthResponse(
        message: 'Terjadi kesalahan jaringan atau server tidak merespons.',
      );
    }
  }
}
