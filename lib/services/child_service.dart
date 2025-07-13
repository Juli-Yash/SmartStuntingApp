// lib/services/child_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_stunting_app/services/auth_service.dart'; // Untuk mendapatkan token
import 'package:smart_stunting_app/models/child.dart'; // Import Child model
import 'package:smart_stunting_app/models/auth_response.dart'; // Untuk respons standar (message, errors)

class ChildService {
  final String _baseUrl = 'http://147.93.106.201/api';
  final AuthService _authService = AuthService(); // Untuk akses token

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('User not authenticated. No token found.');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET /api/anak - Mendapatkan daftar semua anak
  Future<List<Child>> fetchChildren() async {
    final url = Uri.parse('$_baseUrl/anak');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((json) => Child.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        // Token tidak valid/expired, paksa logout
        await _authService.logout();
        throw Exception('Sesi berakhir. Silakan login kembali.');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Gagal memuat daftar anak: ${errorBody['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetchChildren: $e');
      throw Exception(
        'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }

  // GET /api/anak/{id} - Mendapatkan detail satu anak
  Future<Child> fetchChildDetail(int id) async {
    final url = Uri.parse('$_baseUrl/anak/$id');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return Child.fromJson(json);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Sesi berakhir. Silakan login kembali.');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Gagal memuat detail anak: ${errorBody['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetchChildDetail: $e');
      throw Exception(
        'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }

  // POST /api/anak - Menambahkan anak baru
  Future<AuthResponse> addChild(Child child) async {
    final url = Uri.parse('$_baseUrl/anak');
    try {
      final headers = await _getAuthHeaders();
      // Pastikan toJson mencakup user_id untuk POST
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(
          child.toJson(includeUserId: true),
        ), // Include user_id for creation
      );

      final responseBody = jsonDecode(response.body);
      print(
        'Add Child API Response: $responseBody (Status: ${response.statusCode})',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse(
          message: 'Data anak berhasil ditambahkan!',
        ); // API cuma return id dan nama, kita kasih custom message
      } else {
        return AuthResponse.fromJson(responseBody); // Handle validation errors
      }
    } catch (e) {
      print('Error addChild: $e');
      return AuthResponse(
        message: 'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }

  // PUT /api/anak/{id} - Memperbarui data anak
  Future<AuthResponse> updateChild(
    int id,
    Map<String, dynamic> updateData,
  ) async {
    final url = Uri.parse('$_baseUrl/anak/$id');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(updateData), // Kirim hanya data yang ingin diupdate
      );

      final responseBody = jsonDecode(response.body);
      print(
        'Update Child API Response: $responseBody (Status: ${response.statusCode})',
      );

      if (response.statusCode == 200) {
        return AuthResponse(
          message: 'Data anak berhasil diperbarui!',
        ); // API cuma return id, berat, tinggi
      } else {
        return AuthResponse.fromJson(responseBody);
      }
    } catch (e) {
      print('Error updateChild: $e');
      return AuthResponse(
        message: 'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }

  // DELETE /api/anak/{id} - Menghapus anak
  Future<AuthResponse> deleteChild(int id) async {
    final url = Uri.parse('$_baseUrl/anak/$id');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(url, headers: headers);

      final responseBody = jsonDecode(response.body);
      print(
        'Delete Child API Response: $responseBody (Status: ${response.statusCode})',
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(
          responseBody,
        ); // Biasanya hanya "message": "Deleted successfully"
      } else {
        return AuthResponse(
          message: responseBody['message'] ?? 'Gagal menghapus anak.',
        );
      }
    } catch (e) {
      print('Error deleteChild: $e');
      return AuthResponse(
        message: 'Terjadi kesalahan jaringan atau server tidak merespons: $e',
      );
    }
  }
}
