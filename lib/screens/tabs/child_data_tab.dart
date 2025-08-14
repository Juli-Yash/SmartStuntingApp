// lib/screens/tabs/child_data_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_stunting_app/models/child.dart';
import 'package:smart_stunting_app/services/child_service.dart';
import 'package:smart_stunting_app/screens/add_child_screen.dart';
import 'package:smart_stunting_app/screens/edit_child_screen.dart';
import 'package:smart_stunting_app/screens/child_screen.dart';

class ChildDataTab extends StatefulWidget {
  const ChildDataTab({super.key});

  @override
  State<ChildDataTab> createState() => _ChildDataTabState();
}

class _ChildDataTabState extends State<ChildDataTab> {
  late Future<List<Child>> _childrenFuture;
  final ChildService _childService = ChildService();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  // Metode untuk memuat data anak dari API
  void _loadChildren() {
    setState(() {
      _childrenFuture = _childService.fetchChildren();
    });
  }

  // Metode untuk menghapus data anak
  Future<void> _deleteChild(int childId, String childName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Anak: $childName?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data anak ini? Data antropometri terkait juga akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menghapus $childName...'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        // Panggil service untuk menghapus anak
        await _childService.deleteChild(childId);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$childName berhasil dihapus!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadChildren();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menghapus $childName: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Anak'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Child>>(
        future: _childrenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
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
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadChildren,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.child_care, color: Colors.grey, size: 80),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum ada data anak. Tambahkan sekarang!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            // Tampilkan daftar anak
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final child = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        child.gender.toLowerCase() == 'laki-laki'
                            ? Icons.male
                            : Icons.female,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      child.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Lahir: ${DateFormat('dd MMMM yyyy').format(child.birthDate)} - ${child.gender}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol Edit
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditChildScreen(child: child),
                              ),
                            );
                            if (result == true) {
                              _loadChildren();
                            }
                          },
                        ),
                        // Tombol Hapus
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            if (child.id != null) {
                              _deleteChild(child.id!, child.name);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'ID anak tidak ditemukan untuk dihapus.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChildScreen(child: child),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddChildScreen()),
          );
          if (result == true) {
            _loadChildren();
          }
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
