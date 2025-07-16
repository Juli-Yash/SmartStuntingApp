// lib/screens/edit_child_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:smart_stunting_app/models/child.dart';
import 'package:smart_stunting_app/services/child_service.dart';
import 'package:smart_stunting_app/models/auth_response.dart'; // Untuk respons standar

class EditChildScreen extends StatefulWidget {
  final Child child; // Menerima data anak yang akan diedit

  const EditChildScreen({super.key, required this.child});

  @override
  State<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final ChildService _childService = ChildService();

  // Controllers untuk input teks
  late TextEditingController _nameController;
  late String _selectedGender;
  late DateTime? _selectedDateOfBirth;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _headCircumferenceController;
  late TextEditingController _armCircumferenceController;
  late TextEditingController _districtController;
  late String? _selectedVitaminA;
  late String? _selectedFatherEducation;
  late String? _selectedMotherEducation;

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Dropdown options
  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _vitaminAOptions = ['0', '1', '2', '3', '4', '5'];
  final List<String> _educationOptions = [
    'Tidak Sekolah',
    'SD',
    'SMP',
    'SMA',
    'Diploma',
    'Sarjana',
    'Pascasarjana',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.nama);
    _selectedGender = widget.child.jenisKelamin;
    _selectedDateOfBirth = widget.child.tanggalLahir;
    _weightController = TextEditingController(
      text: widget.child.berat.toString(),
    );
    _heightController = TextEditingController(
      text: widget.child.tinggi.toString(),
    );
    _headCircumferenceController = TextEditingController(
      text: widget.child.lingkarKepala?.toString() ?? '',
    );
    _armCircumferenceController = TextEditingController(
      text: widget.child.lingkarLengan?.toString() ?? '',
    );
    _districtController = TextEditingController(
      text: widget.child.kecamatan ?? '',
    );
    _selectedVitaminA = widget.child.jumlahVitA?.toString() ?? '0';
    _selectedFatherEducation = widget.child.pendidikanAyah;
    _selectedMotherEducation = widget.child.pendidikanIbu;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _headCircumferenceController.dispose();
    _armCircumferenceController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  int _calculateAgeInMonths(DateTime dob) {
    final now = DateTime.now();
    int months = (now.year - dob.year) * 12;
    months -= dob.month;
    months += now.month;
    if (now.day < dob.day) {
      months--;
    }
    return months;
  }

  Future<void> _updateChild() async {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateOfBirth == null) {
      setState(() {
        _errorMessage = 'Tanggal lahir tidak boleh kosong.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final int ageInMonths = _calculateAgeInMonths(_selectedDateOfBirth!);

      Map<String, dynamic> updateData = {
        'nama': _nameController.text,
        'jenis_kelamin': _selectedGender,
        'umur_bulan': ageInMonths,
        'berat': double.parse(_weightController.text),
        'tinggi': double.parse(_heightController.text),
        'tanggal_lahir': DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
        // Hanya tambahkan yang opsional jika tidak kosong
        if (_headCircumferenceController.text.isNotEmpty)
          'lingkar_kepala': double.parse(_headCircumferenceController.text),
        if (_armCircumferenceController.text.isNotEmpty)
          'lingkar_lengan': double.parse(_armCircumferenceController.text),
        if (_districtController.text.isNotEmpty)
          'kecamatan': _districtController.text,
        if (_selectedVitaminA != null)
          'jumlah_vit_a': int.parse(_selectedVitaminA!),
        if (_selectedFatherEducation != null)
          'pendidikan_ayah': _selectedFatherEducation,
        if (_selectedMotherEducation != null)
          'pendidikan_ibu': _selectedMotherEducation,
      };

      final AuthResponse response = await _childService.updateChild(
        widget.child.id,
        updateData,
      );

      if (response.message != null && response.accessToken == null) {
        setState(() {
          _successMessage = response.message!;
          _errorMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (response.errors != null && response.errors!.isNotEmpty) {
        setState(() {
          _errorMessage = 'Gagal memperbarui anak:';
          response.errors!.forEach((key, value) {
            _errorMessage += '\n$key: ${value.join(', ')}';
          });
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Terjadi kesalahan tidak dikenal.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Data Anak'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ubah Detail Anak',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Anak',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama anak tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Jenis Kelamin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.wc, color: Colors.blue),
                  ),
                  items: _genderOptions.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jenis kelamin tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _selectDateOfBirth(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: TextEditingController(
                        text: _selectedDateOfBirth == null
                            ? ''
                            : DateFormat(
                                'dd MMMM yyyy',
                              ).format(_selectedDateOfBirth!),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tanggal Lahir',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
                        ),
                      ),
                      validator: (value) {
                        if (_selectedDateOfBirth == null) {
                          return 'Tanggal lahir tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: 'Berat Badan (kg)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.scale, color: Colors.blue),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Berat badan tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    labelText: 'Tinggi Badan (cm)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.height, color: Colors.blue),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tinggi badan tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _headCircumferenceController,
                  decoration: InputDecoration(
                    labelText: 'Lingkar Kepala (cm) (Opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.accessibility_new,
                      color: Colors.blue,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _armCircumferenceController,
                  decoration: InputDecoration(
                    labelText: 'Lingkar Lengan Atas (cm) (Opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.line_weight,
                      color: Colors.blue,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _districtController,
                  decoration: InputDecoration(
                    labelText: 'Kecamatan (Opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedVitaminA,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Pemberian Vit. A',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.medical_services,
                      color: Colors.blue,
                    ),
                  ),
                  items: _vitaminAOptions.map((String count) {
                    return DropdownMenuItem<String>(
                      value: count,
                      child: Text('$count kali'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedVitaminA = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih jumlah pemberian Vit. A';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedFatherEducation,
                  decoration: InputDecoration(
                    labelText: 'Pendidikan Ayah (Opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.school, color: Colors.blue),
                  ),
                  items: _educationOptions.map((String education) {
                    return DropdownMenuItem<String>(
                      value: education,
                      child: Text(education),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFatherEducation = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedMotherEducation,
                  decoration: InputDecoration(
                    labelText: 'Pendidikan Ibu (Opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.school, color: Colors.blue),
                  ),
                  items: _educationOptions.map((String education) {
                    return DropdownMenuItem<String>(
                      value: education,
                      child: Text(education),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMotherEducation = newValue;
                    });
                  },
                ),
                const SizedBox(height: 30),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_successMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _successMessage,
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
                    : ElevatedButton(
                        onPressed: _updateChild,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
