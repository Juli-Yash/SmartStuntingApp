// lib/screens/detail_child_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_stunting_app/models/child.dart';
import 'package:smart_stunting_app/models/antropometry_record.dart';
import 'package:smart_stunting_app/services/antropometry_service.dart';
import 'package:smart_stunting_app/screens/add_antropometry_screen.dart';
import 'package:smart_stunting_app/screens/antropometry_screen.dart';
import 'package:smart_stunting_app/screens/prediction_detail_screen.dart';
import 'package:smart_stunting_app/screens/detail_child_screen.dart';

class ChildScreen extends StatefulWidget {
  final Child child;

  const ChildScreen({super.key, required this.child});

  @override
  State<ChildScreen> createState() => _ChildScreenState();
}

class _ChildScreenState extends State<ChildScreen> {
  final AntropometryService _antropometryService = AntropometryService();
  List<AntropometryRecord> _antropometryRecords = [];
  bool _isLoadingAntropometry = true;
  String? _antropometryErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadAntropometryData();
  }

  Future<void> _loadAntropometryData() async {
    setState(() {
      _isLoadingAntropometry = true;
      _antropometryErrorMessage = null;
    });
    try {
      final records = await _antropometryService.fetchAntropometryRecords();
      _antropometryRecords = records
          .where((r) => r.anakId == widget.child.id)
          .toList();

      // Urutkan berdasarkan tanggal pembuatan (terbaru di atas)
      _antropometryRecords.sort(
        (a, b) => (b.createdAt ?? DateTime(1900)).compareTo(
          a.createdAt ?? DateTime(1900),
        ),
      );

      setState(() {
        _isLoadingAntropometry = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _antropometryErrorMessage =
              'Gagal memuat data antropometri: ${e.toString().replaceFirst('Exception: ', '')}';
          _isLoadingAntropometry = false;
        });
        print('Error loading antropometry data in ChildDetailScreen: $e');
      }
    }
  }

  void _navigateToAddAntropometry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAntropometryScreen(childId: widget.child.id!),
      ),
    );

    if (result == true) {
      _loadAntropometryData();
    }
  }

  Future<void> _deleteRecord(int recordId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus record antropometri ini?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoadingAntropometry = true;
      });
      try {
        final response = await _antropometryService.deleteAntropometryRecord(
          recordId,
        );
        if (mounted) {
          if (response.errors != null && response.errors!.isNotEmpty) {
            String errorMessage =
                response.message ?? 'Gagal menghapus data antropometri.';
            response.errors!.forEach((key, value) {
              errorMessage += '\n- ${value.join(', ')}';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response.message ?? 'Record antropometri berhasil dihapus',
                ),
                backgroundColor: Colors.green,
              ),
            );
            _loadAntropometryData();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error menghapus record antropometri: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoadingAntropometry = false;
          });
        }
      }
    }
  }

  int _calculateAgeInMonths(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    if (months < 0 || (months == 0 && now.day < birthDate.day)) {
      years--;
      months += 12;
    }
    return years * 12 + months;
  }

  Color _getCardColorBasedOnStatus(String? statusStunting) {
    if (statusStunting == null) {
      return Colors.grey.shade200;
    }
    final normalizedStatus = statusStunting.toLowerCase();
    switch (normalizedStatus) {
      case 'stunting':
      case 'severe stunting':
        return Colors.red.shade100;
      case 'moderate stunting':
        return Colors.orange.shade100;
      case 'tall':
        return Colors.yellow.shade100;
      case 'normal':
        return Colors.green.shade100;
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
      case 'stunting':
      case 'severe stunting':
        return Colors.red.shade300;
      case 'moderate stunting':
        return Colors.orange.shade300;
      case 'tall':
        return Colors.yellow.shade300;
      case 'normal':
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    int ageInMonths = _calculateAgeInMonths(widget.child.birthDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Anak'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildChildProfileCard(ageInMonths),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data Antropometri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (widget.child.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AntropometryScreen(childId: widget.child.id!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ID anak tidak ditemukan untuk melihat detail antropometri.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Lihat Semua'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 20, thickness: 1, color: Colors.grey),
          ),
          Expanded(
            child: _isLoadingAntropometry
                ? const Center(child: CircularProgressIndicator())
                : _antropometryErrorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _antropometryErrorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  )
                : _antropometryRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 50,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Belum ada data antropometri untuk anak ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _navigateToAddAntropometry,
                          icon: const Icon(Icons.add_chart),
                          label: const Text('Tambah Data Antropometri Pertama'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAntropometryData,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _antropometryRecords.length,
                      itemBuilder: (context, index) {
                        final record = _antropometryRecords[index];
                        return Card(
                          color: _getCardColorBasedOnStatus(
                            record.predictionRecord?.statusStunting,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _getBorderColorBasedOnStatus(
                                record.predictionRecord?.statusStunting,
                              ),
                              width: 1.5,
                            ),
                          ),
                          margin: const EdgeInsets.only(
                            top: 8,
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          elevation: 4,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (record.predictionRecord != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PredictionDetailScreen(
                                          prediction: record.predictionRecord!,
                                          antropometryRecord: record,
                                        ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tidak ada data prediksi untuk catatan antropometri ini.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Pengukuran Ke-${_antropometryRecords.length - index}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                        onPressed: () =>
                                            _deleteRecord(record.id!),
                                        tooltip: 'Hapus data ini',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tanggal: ${record.createdAt != null ? DateFormat('dd-MM-yyyy').format(record.createdAt!) : 'N/A'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Usia: ${record.ageInMonth} bulan',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Berat Badan: ${record.weight} kg',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Tinggi Badan: ${record.height} cm',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (record.headCircumference != null)
                                    Text(
                                      'Lingkar Kepala: ${record.headCircumference} cm',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  if (record.upperArmCircumference != null)
                                    Text(
                                      'Lingkar Lengan Atas: ${record.upperArmCircumference} cm',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  if (record.vitaminACount != null)
                                    Text(
                                      'Frekuensi Pemberian Kapsul Vit. A: ${record.vitaminACount} kali',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  if (record.predictionRecord != null) ...[
                                    const Divider(height: 20, thickness: 1),
                                    const Text(
                                      'Hasil Prediksi (Klik untuk Detail):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPredictionStatusRow(
                                      'Tinggi menurut Umur',
                                      record.predictionRecord!.statusStunting,
                                    ),
                                    _buildPredictionStatusRow(
                                      'Berat menurut Umur',
                                      record
                                          .predictionRecord!
                                          .statusUnderweight,
                                    ),
                                    _buildPredictionStatusRow(
                                      'Berat menurut Tinggi',
                                      record.predictionRecord!.statusWasting,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton:
          _antropometryRecords.isEmpty &&
              !_isLoadingAntropometry &&
              _antropometryErrorMessage == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToAddAntropometry,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_chart),
              label: const Text('Tambah Antropometri'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildChildProfileCard(int ageInMonths) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
        child: Card(
          color: Colors.blue,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChildDetailScreen(child: widget.child),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      widget.child.gender.toLowerCase() == 'laki-laki'
                          ? Icons.male
                          : Icons.female,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.child.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jenis Kelamin: ${widget.child.gender}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    'Tanggal Lahir: ${DateFormat('dd MMMM yyyy').format(widget.child.birthDate)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    'Usia: $ageInMonths bulan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionStatusRow(String label, String? status) {
    String displayStatus = status ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 14)),
          Text(
            displayStatus,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
