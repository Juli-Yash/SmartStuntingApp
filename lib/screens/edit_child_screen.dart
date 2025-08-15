// lib/screens/edit_child_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_stunting_app/models/child.dart';
import 'package:smart_stunting_app/services/child_service.dart';

class EditChildScreen extends StatefulWidget {
  final Child child; // Menerima objek Child untuk diedit

  const EditChildScreen({super.key, required this.child});

  @override
  State<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final ChildService _childService = ChildService();

  late TextEditingController _nameController;
  late DateTime _selectedBirthDate;
  String? _selectedGender;
  late TextEditingController _regionController;
  String? _selectedFatherEdu;
  String? _selectedMotherEdu;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _educationOptions = [
    'SD',
    'SMP',
    'SMA',
    'Diploma',
    'Sarjana',
    'Magister',
    'Doktor',
    'Tidak Berpendidikan',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi controller dan variabel dengan data anak yang diterima
    _nameController = TextEditingController(text: widget.child.name);
    _selectedBirthDate = widget.child.birthDate;
    _selectedGender = widget.child.gender;
    _regionController = TextEditingController(text: widget.child.region);
    _selectedFatherEdu = widget.child.fatherEdu;
    _selectedMotherEdu = widget.child.motherEdu;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _updateChild() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Child updatedChild = Child(
        id: widget.child.id, // Pastikan ID anak yang sama
        // userId: 0, // Pastikan ini benar sesuai kebutuhan API Anda
        name: _nameController.text,
        gender: _selectedGender!,
        birthDate: _selectedBirthDate,
        region: _regionController.text,
        fatherEdu: _selectedFatherEdu!,
        motherEdu: _selectedMotherEdu!,
      );

      await _childService.updateChild(
        updatedChild,
      ); // Panggil metode updateChild

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data anak berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error memperbarui: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  'Perbarui informasi anak ${widget.child.name}',
                  style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                // Nama Anak
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap Anak',
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
                // Tanggal Lahir
                InputDecorator(
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMMM yyyy').format(_selectedBirthDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _selectBirthDate(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Jenis Kelamin
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Jenis Kelamin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.blue,
                    ),
                  ),
                  items: _genderOptions.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih jenis kelamin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Region/Daerah Asal
                TextFormField(
                  controller: _regionController,
                  decoration: InputDecoration(
                    labelText: 'Asal Daerah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Asal daerah tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Pendidikan Ayah
                DropdownButtonFormField<String>(
                  value: _selectedFatherEdu,
                  decoration: InputDecoration(
                    labelText: 'Pendidikan Terakhir Ayah',
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
                      _selectedFatherEdu = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih pendidikan ayah';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Pendidikan Ibu
                DropdownButtonFormField<String>(
                  value: _selectedMotherEdu,
                  decoration: InputDecoration(
                    labelText: 'Pendidikan Terakhir Ibu',
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
                      _selectedMotherEdu = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih pendidikan ibu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
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
                          'UPDATE DATA ANAK',
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
