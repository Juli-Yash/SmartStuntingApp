// lib/models/riwayat.dart
import 'package:intl/intl.dart'; // Untuk format tanggal

class Riwayat {
  final int id;
  final int anakId;
  final DateTime timestamp;
  final String statusStunting;
  final String statusUnderweight;
  final String statusWasting;
  final String rekomendasi;
  // Jika ada data anak nested di sini (seperti di GET /api/riwayat), bisa ditambahkan
  // final Child? anak; // Import Child model jika perlu

  Riwayat({
    required this.id,
    required this.anakId,
    required this.timestamp,
    required this.statusStunting,
    required this.statusUnderweight,
    required this.statusWasting,
    required this.rekomendasi,
    // this.anak,
  });

  factory Riwayat.fromJson(Map<String, dynamic> json) {
    return Riwayat(
      id: json['id'] as int,
      anakId: json['anak_id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      statusStunting: json['status_stunting'] as String,
      statusUnderweight: json['status_underweight'] as String,
      statusWasting: json['status_wasting'] as String,
      rekomendasi: json['rekomendasi'] as String,
      // anak: json['anak'] != null ? Child.fromJson(json['anak']) : null, // Jika ada anak nested
    );
  }

  // Helper untuk mendapatkan tanggal yang diformat
  String get formattedTimestamp {
    return DateFormat('dd MMMM yyyy HH:mm').format(timestamp);
  }
}
