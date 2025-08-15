// lib/screens/add_antropometry_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/antropometry_record.dart';
import 'package:smart_stunting_app/models/child.dart';
import 'package:smart_stunting_app/services/antropometry_service.dart';
import 'package:smart_stunting_app/services/child_service.dart';
import 'package:intl/intl.dart';

class AddAntropometryScreen extends StatefulWidget {
  final int childId;

  const AddAntropometryScreen({Key? key, required this.childId})
    : super(key: key);

  @override
  State<AddAntropometryScreen> createState() => _AddAntropometryScreenState();
}

class _AddAntropometryScreenState extends State<AddAntropometryScreen> {
  final _formKey = GlobalKey<FormState>();
  final AntropometryService _antropometryService = AntropometryService();
  final ChildService _childService = ChildService();

  Child? _currentChild;
  bool _isLoadingChild = true;
  bool _isSaving = false;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _headCircumferenceController =
      TextEditingController();
  final TextEditingController _upperArmCircumferenceController =
      TextEditingController();

  // Variabel untuk menyimpan usia yang dihitung
  int _calculatedAge = 0;
  DateTime _selectedDate = DateTime.now();

  // Variabel baru untuk pilihan pengukuran tinggi/panjang badan
  String? _selectedHeightMeasurement;
  final List<String> _heightMeasurements = ['Panjang Badan', 'Tinggi Badan'];
  final double _adjustmentValue = 0.7; // Konstanta untuk penyesuaian

  int? _selectedVitaminACount;
  final List<int> _vitaminADoses = [0, 1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _fetchChildDetails();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _headCircumferenceController.dispose();
    _upperArmCircumferenceController.dispose();
    super.dispose();
  }

  Future<void> _fetchChildDetails() async {
    try {
      final child = await _childService.fetchChild(widget.childId);
      setState(() {
        _currentChild = child;
        _isLoadingChild = false;
        // Hitung usia anak saat data dimuat
        _calculatedAge = _calculateAgeInMonths(_selectedDate);
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Gagal memuat detail anak: ${e.toString().replaceFirst('Exception: ', '')}',
          Colors.red,
        );
        setState(() {
          _isLoadingChild = false;
        });
      }
    }
  }

  int _calculateAgeInMonths(DateTime recordDate) {
    if (_currentChild == null) {
      return 0;
    }
    DateTime dob = _currentChild!.birthDate;
    int months =
        (recordDate.year - dob.year) * 12 + recordDate.month - dob.month;
    if (recordDate.day < dob.day) {
      months--;
    }
    return months < 0 ? 0 : months;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _currentChild?.birthDate ?? DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Hitung ulang usia saat tanggal pengukuran berubah
        _calculatedAge = _calculateAgeInMonths(_selectedDate);
      });
    }
  }

  void _saveAntropometry() async {
    if (!_formKey.currentState!.validate() || _currentChild == null) {
      if (_currentChild == null) {
        _showSnackBar(
          'Data anak belum dimuat. Tidak bisa menyimpan antropometri.',
          Colors.orange,
        );
      }
      return;
    }

    if (_selectedVitaminACount == null) {
      _showSnackBar('Dosis Vitamin A harus dipilih.', Colors.red);
      return;
    }

    // Validasi pilihan pengukuran
    if (_selectedHeightMeasurement == null) {
      _showSnackBar(
        'Jenis pengukuran tinggi/panjang badan harus dipilih.',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final double weight = double.parse(_weightController.text);
      double height = double.parse(_heightController.text);
      final int ageInMonth = _calculatedAge;

      // --- LOGIKA PENYESUAIAN PENTING DI SINI ---
      if (ageInMonth < 25) {
        // Anak di bawah 25 bulan, seharusnya diukur PB
        if (_selectedHeightMeasurement == 'Tinggi Badan') {
          // Jika diukur TB, tambahkan 0.7 cm
          height += _adjustmentValue;
        }
      } else {
        // Anak di atas 25 bulan, seharusnya diukur TB
        if (_selectedHeightMeasurement == 'Panjang Badan') {
          // Jika diukur PB, kurangi 0.7 cm
          height -= _adjustmentValue;
        }
      }

      final int? vitaminACount = _selectedVitaminACount;

      final double? headCircumference =
          _headCircumferenceController.text.isEmpty
          ? null
          : double.tryParse(_headCircumferenceController.text);
      final double? upperArmCircumference =
          _upperArmCircumferenceController.text.isEmpty
          ? null
          : double.tryParse(_upperArmCircumferenceController.text);

      final AntropometryRecord newRecord = AntropometryRecord(
        anakId: _currentChild!.id!,
        ageInMonth: ageInMonth,
        weight: weight,
        height: height,
        vitaminACount: vitaminACount,
        headCircumference: headCircumference,
        upperArmCircumference: upperArmCircumference,
      );

      AntropometryRecord createdRecord = await _antropometryService
          .createAntropometryRecord(newRecord);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        _showSnackBar(
          'Data antropometri berhasil ditambahkan, Id pengukuran: ${createdRecord.anakId}',
          Colors.green,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        _showSnackBar('Error: $errorMessage', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    required String suffixText,
    required String? Function(String?) validator,
    TextInputType keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    ),
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            suffixText: suffixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.blue.shade200, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.blue, width: 2.0),
            ),
            filled: true,
            fillColor: Colors.blue.shade50,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 16.0,
            ),
          ),
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  // Fungsi baru untuk menampilkan teks keterangan dinamis
  Widget _buildMeasurementInfo() {
    String title;
    String recommendation;
    String automaticAdjustment;
    String explanation;

    if (_calculatedAge < 25) {
      title = 'Panduan Pengukuran untuk Anak Usia < 25 Bulan';
      recommendation =
          'Untuk anak usia di bawah 25 bulan, pengukuran sebaiknya dilakukan dalam posisi berbaring menggunakan alat ukur Panjang Badan (infantometer).';
      automaticAdjustment =
          'Jika Anda memilih untuk mengukur dalam posisi berdiri menggunakan Tinggi Badan (stadiometer), sistem akan secara otomatis menambahkan 0.7 cm pada hasil pengukuran Anda.';
      explanation =
          'Penyesuaian ini krusial untuk memastikan data yang dicatat akurat dan konsisten dengan standar baku WHO, di mana pengukuran berbaring dianggap metode standar untuk kelompok usia ini.';
    } else {
      title = 'Panduan Pengukuran untuk Anak Usia ≥ 25 Bulan';
      recommendation =
          'Untuk anak usia 25 bulan atau lebih, pengukuran sebaiknya dilakukan dalam posisi berdiri menggunakan alat ukur Tinggi Badan (stadiometer).';
      automaticAdjustment =
          'Jika Anda memilih untuk mengukur dalam posisi berbaring menggunakan Panjang Badan (infantometer), sistem akan secara otomatis mengurangi 0.7 cm pada hasil pengukuran Anda.';
      explanation =
          'Hal ini bertujuan untuk menyelaraskan data dengan standar pengukuran berdiri yang direkomendasikan secara global untuk usia ini, sehingga hasil analisis menjadi lebih valid dan dapat dibandingkan.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(recommendation),
              _buildInfoRow(automaticAdjustment),
              _buildInfoRow(explanation),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi pembantu untuk membuat baris teks yang rapi
  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.green.shade700),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Antropometri',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingChild
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : _currentChild == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Gagal memuat data anak.\nSilakan pastikan ID anak valid dan koneksi internet stabil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detail Anak',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Divider(height: 20, thickness: 1),
                            _buildDetailRow(
                              Icons.person,
                              'Nama Anak',
                              _currentChild!.name,
                            ),
                            _buildDetailRow(
                              Icons.cake,
                              'Tanggal Lahir',
                              DateFormat(
                                'dd-MM-yyyy',
                              ).format(_currentChild!.birthDate),
                            ),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Usia',
                              '$_calculatedAge Bulan',
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Keterangan dinamis di sini
                    _buildMeasurementInfo(),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data Pengukuran',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Divider(height: 20, thickness: 1),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Tanggal Pengukuran',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade200,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2.0,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14.0,
                                    horizontal: 16.0,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.blue,
                                  ),
                                ),
                                baseStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd-MM-yyyy',
                                  ).format(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Pilihan Jenis Pengukuran
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: DropdownButtonFormField<String>(
                                value: _selectedHeightMeasurement,
                                decoration: InputDecoration(
                                  labelText: 'Jenis Pengukuran',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                items: _heightMeasurements.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedHeightMeasurement = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Jenis pengukuran harus dipilih';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            _buildFormField(
                              controller: _weightController,
                              labelText: 'Berat Badan',
                              suffixText: 'kg',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Berat badan tidak boleh kosong';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Masukkan angka yang valid (contoh: 8.5)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: _heightController,
                              labelText: 'Tinggi/Panjang Badan',
                              suffixText: 'cm',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Tinggi/Panjang badan tidak boleh kosong';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Masukkan angka yang valid (contoh: 85.0)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: _headCircumferenceController,
                              labelText: 'Lingkar Kepala',
                              suffixText: 'cm',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lingkar kepala tidak boleh kosong';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Masukkan angka yang valid (contoh: 45.0)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: _upperArmCircumferenceController,
                              labelText: 'Lingkar Lengan Atas',
                              suffixText: 'cm',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lingkar lengan atas tidak boleh kosong';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Masukkan angka yang valid (contoh: 12.5)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: DropdownButtonFormField<int>(
                                value: _selectedVitaminACount,
                                decoration: InputDecoration(
                                  labelText:
                                      'Frekuensi Pemberian Kapsul Vit. A',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                items: _vitaminADoses.map((int dose) {
                                  return DropdownMenuItem<int>(
                                    value: dose,
                                    child: Text('$dose kali'),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedVitaminACount = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Frekuensi Pemberian Kapsul Vitamin A harus dipilih.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _saveAntropometry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                'Simpan Antropometri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
