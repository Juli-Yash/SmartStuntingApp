// lib/screens/child_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:smart_stunting_app/models/child.dart';
// import 'package:smart_stunting_app/models/riwayat.dart';
import 'package:smart_stunting_app/services/child_service.dart';
import 'package:smart_stunting_app/screens/edit_child_screen.dart'; // Akan kita buat nanti

class ChildDetailScreen extends StatefulWidget {
  final int childId; // ID anak yang akan ditampilkan

  const ChildDetailScreen({super.key, required this.childId});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  final ChildService _childService = ChildService();
  Child? _childDetail;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchChildDetail();
  }

  Future<void> _fetchChildDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final Child child = await _childService.fetchChildDetail(widget.childId);
      setState(() {
        _childDetail = child;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      // Handle navigation to login if token expired (already handled in ChildService)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_childDetail?.nama ?? 'Detail Anak'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_childDetail != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Data Anak',
              onPressed: () async {
                // Navigasi ke EditChildScreen dan tunggu hasil
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditChildScreen(
                      child: _childDetail!,
                    ), // Kirim objek child
                  ),
                );
                if (result == true) {
                  _fetchChildDetail(); // Muat ulang detail jika berhasil diupdate
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchChildDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _childDetail == null
          ? const Center(child: Text('Data anak tidak ditemukan.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              child: Icon(
                                _childDetail!.jenisKelamin == 'Laki-laki'
                                    ? Icons.male
                                    : Icons.female,
                                size: 45,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: Text(
                              _childDetail!.nama,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const Divider(height: 30),
                          _buildInfoRow(
                            'Jenis Kelamin',
                            _childDetail!.jenisKelamin,
                          ),
                          _buildInfoRow(
                            'Tanggal Lahir',
                            _childDetail!.tanggalLahir != null
                                ? DateFormat(
                                    'dd MMMM yyyy',
                                  ).format(_childDetail!.tanggalLahir!)
                                : '-',
                          ),
                          _buildInfoRow(
                            'Umur (bulan)',
                            _childDetail!.umurBulan.toString(),
                          ),
                          _buildInfoRow(
                            'Berat Badan',
                            '${_childDetail!.berat} kg',
                          ),
                          _buildInfoRow(
                            'Tinggi Badan',
                            '${_childDetail!.tinggi} cm',
                          ),
                          if (_childDetail!.lingkarKepala != null)
                            _buildInfoRow(
                              'Lingkar Kepala',
                              '${_childDetail!.lingkarKepala} cm',
                            ),
                          if (_childDetail!.lingkarLengan != null)
                            _buildInfoRow(
                              'Lingkar Lengan',
                              '${_childDetail!.lingkarLengan} cm',
                            ),
                          if (_childDetail!.kecamatan != null)
                            _buildInfoRow(
                              'Kecamatan',
                              _childDetail!.kecamatan!,
                            ),
                          if (_childDetail!.jumlahVitA != null)
                            _buildInfoRow(
                              'Jumlah Vit. A',
                              '${_childDetail!.jumlahVitA} kali',
                            ),
                          if (_childDetail!.pendidikanAyah != null)
                            _buildInfoRow(
                              'Pendidikan Ayah',
                              _childDetail!.pendidikanAyah!,
                            ),
                          if (_childDetail!.pendidikanIbu != null)
                            _buildInfoRow(
                              'Pendidikan Ibu',
                              _childDetail!.pendidikanIbu!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Riwayat Pengukuran:',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (_childDetail!.riwayats == null ||
                      _childDetail!.riwayats!.isEmpty)
                    const Center(
                      child: Text(
                        'Belum ada riwayat pengukuran untuk anak ini.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true, // Agar ListView tidak makan semua ruang
                      physics:
                          const NeverScrollableScrollPhysics(), // Nonaktifkan scroll ListView
                      itemCount: _childDetail!.riwayats!.length,
                      itemBuilder: (context, index) {
                        final riwayat = _childDetail!.riwayats![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal: ${riwayat.formattedTimestamp}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Status Stunting: ${riwayat.statusStunting}',
                                ),
                                Text(
                                  'Status Underweight: ${riwayat.statusUnderweight}',
                                ),
                                Text(
                                  'Status Wasting: ${riwayat.statusWasting}',
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Rekomendasi: ${riwayat.rekomendasi}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
