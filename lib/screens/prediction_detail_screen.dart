// lib/screens/prediction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_stunting_app/models/prediction_record.dart';
import 'package:smart_stunting_app/models/antropometry_record.dart';

class PredictionDetailScreen extends StatelessWidget {
  final PredictionRecord prediction;
  final AntropometryRecord antropometryRecord;

  const PredictionDetailScreen({
    super.key,
    required this.prediction,
    required this.antropometryRecord,
  });

  Color _getCardColorBasedOnStatus(String? statusStunting) {
    if (statusStunting == null) {
      return Colors.grey.shade200;
    }
    final normalizedStatus = statusStunting.toLowerCase();
    switch (normalizedStatus) {
      case 'sangat pendek':
        return Colors.red.shade100;
      case 'pendek':
        return Colors.orange.shade100;
      case 'normal':
        return Colors.green.shade100;
      case 'tinggi':
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getBorderColorBasedOnStatus(String? statusStunting) {
    if (statusStunting == null) {
      return Colors.grey.shade300;
    }
    final normalizedStatus = statusStunting.toLowerCase();
    switch (normalizedStatus) {
      case 'sangat pendek':
        return Colors.red.shade300;
      case 'pendek':
        return Colors.orange.shade300;
      case 'normal':
        return Colors.green.shade300;
      case 'tinggi':
        return Colors.yellow.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String childName =
        antropometryRecord.anak?.name ?? 'Nama Anak Tidak Diketahui';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Prediksi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: _getCardColorBasedOnStatus(prediction.statusStunting),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getBorderColorBasedOnStatus(prediction.statusStunting),
              width: 1.5,
            ),
          ),
          // --- Akhir bagian yang dimodifikasi ---
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.insights,
                    size: 80,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Ringkasan Hasil Prediksi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 30, thickness: 1.5, color: Colors.blue),

                // --- Informasi Prediksi ---
                const SizedBox(height: 20),
                const Text(
                  'Data Antropometri Terkait:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Nama Anak', childName),

                _buildDetailRow(
                  'Tanggal Pengukuran',
                  antropometryRecord.createdAt != null
                      ? DateFormat(
                          'dd MMMM yyyy',
                        ).format(antropometryRecord.createdAt!)
                      : 'N/A',
                ),
                _buildDetailRow(
                  'Usia',
                  '${antropometryRecord.ageInMonth} bulan',
                ),
                _buildDetailRow(
                  'Berat Badan',
                  '${antropometryRecord.weight} kg',
                ),
                _buildDetailRow(
                  'Tinggi Badan',
                  '${antropometryRecord.height} cm',
                ),
                if (antropometryRecord.headCircumference != null)
                  _buildDetailRow(
                    'Lingkar Kepala',
                    '${antropometryRecord.headCircumference} cm',
                  ),
                if (antropometryRecord.upperArmCircumference != null)
                  _buildDetailRow(
                    'Lingkar Lengan Atas',
                    '${antropometryRecord.upperArmCircumference} cm',
                  ),
                if (antropometryRecord.vitaminACount != null)
                  _buildDetailRow(
                    'Frekuensi Pemberian Kapsul Vit. A',
                    '${antropometryRecord.vitaminACount} kali',
                  ),

                // --- Status Gizi Anak ---
                const SizedBox(height: 20),
                const Text(
                  'Status Gizi Anak:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPredictionStatusRow(
                  'Tinggi berdasarkan Umur',
                  prediction.statusStunting,
                ),
                _buildPredictionStatusRow(
                  'Berat berdasarkan Umur',
                  prediction.statusUnderweight,
                ),
                _buildPredictionStatusRow(
                  'Berat berdasarkan Tinggi',
                  prediction.statusWasting,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Rekomendasi:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    prediction.recommendation,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildPredictionStatusRow(String label, String? status) {
  String displayStatus = status ?? 'N/A';
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              displayStatus,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ),
      ],
    ),
  );
}
