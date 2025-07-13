// lib/models/auth_response.dart
class AuthResponse {
  final String? accessToken; // Akan ada saat login/register sukses
  final String? tokenType; // Biasanya "Bearer"
  final String? message; // Pesan sukses atau pesan error umum
  final Map<String, dynamic>?
  errors; // Detail error validasi (misal: "phone_number already taken")

  AuthResponse({this.accessToken, this.tokenType, this.message, this.errors});

  // Factory method untuk membuat instance AuthResponse dari JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String?,
      tokenType: json['token_type'] as String?,
      message: json['message'] as String?,
      // Cek apakah ada key 'errors' dan pastikan itu Map
      errors: json['errors'] is Map
          ? Map<String, dynamic>.from(json['errors'])
          : null,
    );
  }
}
