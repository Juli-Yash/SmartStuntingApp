// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String phoneNumber;
  // final String? email; // Contoh jika ada email

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    // this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      // email: json['email'] as String?,
    );
  }

  // Metode to map for sending data to API (misal untuk update)
  Map<String, dynamic> toJson() {
    return {'name': name, 'phone_number': phoneNumber};
  }
}
