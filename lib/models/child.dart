// lib/models/child.dart
import 'package:smart_stunting_app/models/riwayat.dart'; // Import Riwayat model

class Child {
  final int id;
  final int userId; // Assuming user_id is returned
  final String nama;
  final String jenisKelamin;
  final int umurBulan;
  final double berat;
  final double tinggi;
  final double? lingkarKepala; // Optional, only in POST/detail
  final double? lingkarLengan; // Optional
  final String? kecamatan; // Optional
  final int? jumlahVitA; // Optional
  final String? pendidikanAyah; // Optional
  final String? pendidikanIbu; // Optional
  final String? statusGizi; // Optional, from POST
  final DateTime? tanggalLahir; // Optional, from POST/detail

  final List<Riwayat>?
  riwayats; // Only available when fetching single child by ID

  Child({
    required this.id,
    required this.userId,
    required this.nama,
    required this.jenisKelamin,
    required this.umurBulan,
    required this.berat,
    required this.tinggi,
    this.lingkarKepala,
    this.lingkarLengan,
    this.kecamatan,
    this.jumlahVitA,
    this.pendidikanAyah,
    this.pendidikanIbu,
    this.statusGizi,
    this.tanggalLahir,
    this.riwayats,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    // Parsing riwayats jika ada (untuk GET /api/anak/{id})
    List<Riwayat>? parsedRiwayats;
    if (json['riwayats'] != null) {
      parsedRiwayats = (json['riwayats'] as List)
          .map((i) => Riwayat.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return Child(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      nama: json['nama'] as String,
      jenisKelamin: json['jenis_kelamin'] as String,
      umurBulan: json['umur_bulan'] as int,
      berat: (json['berat'] as num).toDouble(),
      tinggi: (json['tinggi'] as num).toDouble(),
      lingkarKepala: (json['lingkar_kepala'] as num?)?.toDouble(),
      lingkarLengan: (json['lingkar_lengan'] as num?)?.toDouble(),
      kecamatan: json['kecamatan'] as String?,
      jumlahVitA: json['jumlah_vit_a'] as int?,
      pendidikanAyah: json['pendidikan_ayah'] as String?,
      pendidikanIbu: json['pendidikan_ibu'] as String?,
      statusGizi: json['status_gizi'] as String?,
      tanggalLahir: json['tanggal_lahir'] != null
          ? DateTime.tryParse(json['tanggal_lahir'] as String)
          : null,
      riwayats: parsedRiwayats,
    );
  }

  // Metode untuk membuat Map data yang siap dikirim ke API (POST/PUT)
  Map<String, dynamic> toJson({bool includeUserId = false}) {
    final Map<String, dynamic> data = {
      'nama': nama,
      'jenis_kelamin': jenisKelamin,
      'umur_bulan': umurBulan,
      'berat': berat,
      'tinggi': tinggi,
      // Tambahkan properti opsional jika ada dan tidak null
      if (lingkarKepala != null) 'lingkar_kepala': lingkarKepala,
      if (lingkarLengan != null) 'lingkar_lengan': lingkarLengan,
      if (kecamatan != null) 'kecamatan': kecamatan,
      if (jumlahVitA != null) 'jumlah_vit_a': jumlahVitA,
      if (pendidikanAyah != null) 'pendidikan_ayah': pendidikanAyah,
      if (pendidikanIbu != null) 'pendidikan_ibu': pendidikanIbu,
      if (statusGizi != null) 'status_gizi': statusGizi,
      if (tanggalLahir != null)
        'tanggal_lahir': tanggalLahir!
            .toIso8601String()
            .split('T')
            .first, // Format YYYY-MM-DD
    };
    if (includeUserId) {
      data['user_id'] = userId;
    }
    return data;
  }
}
