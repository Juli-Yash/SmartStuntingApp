// lib/services/berita_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_stunting_app/models/berita.dart';
import 'package:smart_stunting_app/services/auth_service.dart'; // Import AuthService untuk token

class BeritaService {
  final String _baseUrl = 'http://147.93.106.201/api';
  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Token not found. User is not authenticated.');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET /api/berita
  Future<List<Berita>> fetchAllBerita() async {
    final url = Uri.parse('$_baseUrl/berita');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((berita) => Berita.fromJson(berita)).toList();
      } else if (response.statusCode == 401) {
        // Token tidak valid, mungkin perlu logout atau refresh token
        await _authService.logout(); // Paksa logout
        throw Exception('Unauthorized: Please login again.');
      } else {
        throw Exception(
          'Failed to load berita: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching all berita: $e');
      throw Exception('Failed to connect to the server or retrieve data.');
    }
  }

  // GET /api/berita/{id}
  Future<Berita> fetchBeritaById(int id) async {
    final url = Uri.parse('$_baseUrl/berita/$id');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return Berita.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Unauthorized: Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Berita with ID $id not found.');
      } else {
        throw Exception(
          'Failed to load berita: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching berita by ID ($id): $e');
      throw Exception('Failed to connect to the server or retrieve data.');
    }
  }

  // POST /api/berita
  Future<Berita> createBerita(Berita berita) async {
    final url = Uri.parse('$_baseUrl/berita');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(
          berita.toJson(),
        ), // Menggunakan toJson dari model Berita
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Berita.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Unauthorized: Please login again.');
      } else {
        throw Exception(
          'Failed to create berita: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error creating berita: $e');
      throw Exception('Failed to connect to the server or create data.');
    }
  }

  // PUT /api/berita/{id}
  Future<Berita> updateBerita(int id, Berita berita) async {
    final url = Uri.parse('$_baseUrl/berita/$id');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(berita.toJson()),
      );

      if (response.statusCode == 200) {
        return Berita.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Unauthorized: Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Berita with ID $id not found for update.');
      } else {
        throw Exception(
          'Failed to update berita: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating berita ($id): $e');
      throw Exception('Failed to connect to the server or update data.');
    }
  }

  // DELETE /api/berita/{id}
  Future<void> deleteBerita(int id) async {
    final url = Uri.parse('$_baseUrl/berita/$id');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        print('Berita with ID $id deleted successfully.');
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Unauthorized: Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Berita with ID $id not found for deletion.');
      } else {
        throw Exception(
          'Failed to delete berita: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting berita ($id): $e');
      throw Exception('Failed to connect to the server or delete data.');
    }
  }
}
