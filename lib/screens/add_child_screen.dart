// lib/screens/add_child_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_stunting_app/models/child.dart';
import 'package:smart_stunting_app/services/child_service.dart';
import 'package:smart_stunting_app/services/auth_service.dart'; // <<< TAMBAHKAN INI
import 'package:smart_stunting_app/models/auth_response.dart';
import 'package:smart_stunting_app/screens/login_screen.dart'; // Opsional: Untuk redirect jika user_id tidak ditemukan

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final ChildService _childService = ChildService();
  final AuthService _authService =
      AuthService(); // <<< Inisialisasi AuthService

  // Controllers untuk input teks
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Laki-laki'; // Default gender
  DateTime? _selectedDateOfBirth;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _headCircumferenceController =
      TextEditingController(); // Lingkar Kepala
  final TextEditingController _armCircumferenceController =
      TextEditingController(); // Lingkar Lengan
  final TextEditingController _districtController =
      TextEditingController(); // Kecamatan
  String? _selectedVitaminA = '0'; // Default Vitamin A
  String? _selectedFatherEducation; // Pendidikan Ayah
  String? _selectedMotherEducation; // Pendidikan Ibu

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Dropdown options
  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _vitaminAOptions = ['0', '1', '2']; // Jumlah Vit A
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
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _headCircumferenceController.dispose();
    _armCircumferenceController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih tanggal lahir
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(2000), // Batasan tanggal awal
      lastDate: DateTime.now(), // Batasan tanggal akhir (hari ini)
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  // Fungsi untuk menghitung umur dalam bulan
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

  Future<void> _addChild() async {
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

      // --- START PERBAIKAN: Ambil user_id yang sebenarnya ---
      final int? currentUserId = await _authService.getUserId();
      if (currentUserId == null) {
        setState(() {
          _errorMessage = 'ID pengguna tidak ditemukan. Harap login kembali.';
        });
        // Opsional: Arahkan pengguna ke LoginScreen jika ID tidak ditemukan
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
        return; // Hentikan proses jika user_id tidak ada
      }
      // --- END PERBAIKAN ---

      final newChild = Child(
        id: 0, // ID akan di-generate oleh server
        userId:
            currentUserId, // <<< GUNAKAN ID PENGGUNA YANG SEBENARNYA DI SINI
        nama: _nameController.text,
        jenisKelamin: _selectedGender,
        umurBulan: ageInMonths,
        berat: double.parse(_weightController.text),
        tinggi: double.parse(_heightController.text),
        lingkarKepala: _headCircumferenceController.text.isNotEmpty
            ? double.parse(_headCircumferenceController.text)
            : null,
        lingkarLengan: _armCircumferenceController.text.isNotEmpty
            ? double.parse(_armCircumferenceController.text)
            : null,
        kecamatan: _districtController.text.isNotEmpty
            ? _districtController.text
            : null,
        jumlahVitA: int.parse(_selectedVitaminA!),
        pendidikanAyah: _selectedFatherEducation,
        pendidikanIbu: _selectedMotherEducation,
        statusGizi: null, // Ini akan diisi oleh API setelah webhook
        tanggalLahir: _selectedDateOfBirth!,
      );

      final AuthResponse response = await _childService.addChild(newChild);

      if (response.message != null && response.accessToken == null) {
        // Asumsi sukses jika ada message dan bukan token (karena API POST anak cuma return id, nama)
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
        Navigator.pop(context, true); // Kembali ke ChildDataTab dan refresh
      } else if (response.errors != null && response.errors!.isNotEmpty) {
        setState(() {
          _errorMessage = 'Gagal menambahkan anak:';
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
        _errorMessage =
            'Terjadi kesalahan: $e'; // Mengubah pesan error agar lebih generik
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
        title: const Text('Tambah Data Anak'),
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
                  'Masukkan Detail Anak Baru',
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
                    labelText: 'Lingkar Lengan (cm) (Opsional)',
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
                        onPressed: _addChild,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'SIMPAN DATA ANAK',
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
