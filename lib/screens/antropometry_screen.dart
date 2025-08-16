// lib/screens/antropometry_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/antropometry_record.dart';
import 'package:smart_stunting_app/models/child.dart';
import 'package:smart_stunting_app/services/antropometry_service.dart';
import 'package:smart_stunting_app/services/child_service.dart';
import 'package:smart_stunting_app/screens/add_antropometry_screen.dart';
import 'package:intl/intl.dart';
import 'package:smart_stunting_app/screens/prediction_detail_screen.dart';

class AntropometryScreen extends StatefulWidget {
  final int childId;

  const AntropometryScreen({Key? key, required this.childId}) : super(key: key);

  @override
  State<AntropometryScreen> createState() => _AntropometryScreenState();
}

class _AntropometryScreenState extends State<AntropometryScreen> {
  final AntropometryService _antropometryService = AntropometryService();
  final ChildService _childService = ChildService();

  Child? _currentChild;
  List<AntropometryRecord> _antropometryRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final child = await _childService.fetchChild(widget.childId);
      final records = await _antropometryService.fetchAntropometryRecords();

      _antropometryRecords = records
          .where((r) => r.anakId == widget.childId)
          .toList();

      setState(() {
        _currentChild = child;
        _antropometryRecords.sort(
          (a, b) => (b.createdAt ?? DateTime(1900)).compareTo(
            a.createdAt ?? DateTime(1900),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal memuat data: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
      print('Error loading antropometry data: $e');
    }
  }

  void _navigateToAddAntropometry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAntropometryScreen(childId: widget.childId),
      ),
    );

    if (result == true) {
      _loadData();
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
        _isLoading = true;
      });
      try {
        final authResponse = await _antropometryService
            .deleteAntropometryRecord(recordId);
        if (mounted) {
          if (authResponse.errors != null && authResponse.errors!.isNotEmpty) {
            String errorMessage =
                authResponse.message ?? 'Gagal menghapus data antropometri.';
            authResponse.errors!.forEach((key, value) {
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
                  authResponse.message ??
                      'Record antropometri berhasil dihapus',
                ),
                backgroundColor: Colors.green,
              ),
            );
            _loadData();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error menghapus record: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Antropometri ${_currentChild?.name ?? 'Anak'}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
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
                  const Icon(Icons.info_outline, size: 50, color: Colors.grey),
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
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 80.0,
                ),
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
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (record.predictionRecord != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PredictionDetailScreen(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pengukuran ke-${_antropometryRecords.length - index}',
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
                                  onPressed: () => _deleteRecord(record.id!),
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
                                'Tinggi berdasarkan Umur',
                                record.predictionRecord!.statusStunting,
                              ),
                              _buildPredictionStatusRow(
                                'Berat berdasarkan Umur',
                                record.predictionRecord!.statusUnderweight,
                              ),
                              _buildPredictionStatusRow(
                                'Berat berdasarkan Tinggi',
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
      floatingActionButton:
          _antropometryRecords.isEmpty && !_isLoading && _errorMessage == null
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
