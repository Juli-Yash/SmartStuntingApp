// lib/services/berita_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_stunting_app/models/berita.dart';
import 'package:smart_stunting_app/services/auth_service.dart'; // Import AuthService untuk token

class BeritaService {
  final String _baseUrl = 'http://147.93.106.201/api';
  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  // Helper untuk mendapatkan headers dengan token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      // Lebih baik throw exception yang lebih spesifik untuk ditangkap di UI
      throw Exception('Autentikasi diperlukan. Silakan login kembali.');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET /api/berita - Mendapatkan daftar semua berita
  Future<List<Berita>> fetchAllBerita() async {
    final url = Uri.parse('$_baseUrl/berita');
    print('Fetching berita from: $url'); // Debugging URL
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      print(
        'Berita API Response Status: ${response.statusCode}',
      ); // Debugging status
      print('Berita API Response Body: ${response.body}'); // Debugging body

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((berita) => Berita.fromJson(berita)).toList();
      } else if (response.statusCode == 401) {
        await _authService
            .logout(); // Paksa logout jika token tidak valid/expired
        throw Exception('Sesi berakhir. Silakan login kembali.');
      } else {
        // Coba parsing pesan error dari body jika ada
        String errorMessage = 'Gagal memuat berita.';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          // Gagal parsing body sebagai JSON, gunakan status code
          errorMessage = 'Gagal memuat berita: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetchAllBerita: $e');
      throw Exception(
        'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }

  // GET /api/berita/{id} - Mendapatkan detail satu berita
  Future<Berita> fetchBeritaById(int id) async {
    final url = Uri.parse('$_baseUrl/berita/$id');
    print('Fetching berita by ID $id from: $url'); // Debugging URL
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      print('Berita by ID API Response Status: ${response.statusCode}');
      print('Berita by ID API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return Berita.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Sesi berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception('Berita dengan ID $id tidak ditemukan.');
      } else {
        String errorMessage = 'Gagal memuat detail berita.';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          errorMessage = 'Gagal memuat detail berita: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetchBeritaById ($id): $e');
      throw Exception(
        'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }

  // POST /api/berita
  Future<Berita> createBerita(Berita berita) async {
    final url = Uri.parse('$_baseUrl/berita');
    print('Creating berita to: $url with data: ${berita.toJson()}');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(berita.toJson()),
      );

      print('Create Berita API Response Status: ${response.statusCode}');
      print('Create Berita API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Berita.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Sesi berakhir. Silakan login kembali.');
      } else {
        String errorMessage = 'Gagal membuat berita.';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          errorMessage = 'Gagal membuat berita: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error creating berita: $e');
      throw Exception(
        'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }

  // PUT /api/berita/{id}
  Future<Berita> updateBerita(int id, Berita berita) async {
    final url = Uri.parse('$_baseUrl/berita/$id');
    print('Updating berita $id to: $url with data: ${berita.toJson()}');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(berita.toJson()),
      );

      print('Update Berita API Response Status: ${response.statusCode}');
      print('Update Berita API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return Berita.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Sesi berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception(
          'Berita dengan ID $id tidak ditemukan untuk pembaruan.',
        );
      } else {
        String errorMessage = 'Gagal memperbarui berita.';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          errorMessage = 'Gagal memperbarui berita: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error updating berita ($id): $e');
      throw Exception(
        'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }

  // DELETE /api/berita/{id}
  Future<void> deleteBerita(int id) async {
    final url = Uri.parse('$_baseUrl/berita/$id');
    print('Deleting berita $id from: $url');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(url, headers: headers);

      print('Delete Berita API Response Status: ${response.statusCode}');
      print('Delete Berita API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Berita dengan ID $id berhasil dihapus.');
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Sesi berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception(
          'Berita dengan ID $id tidak ditemukan untuk penghapusan.',
        );
      } else {
        String errorMessage = 'Gagal menghapus berita.';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          errorMessage = 'Gagal menghapus berita: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error deleting berita ($id): $e');
      throw Exception(
        'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }
}
