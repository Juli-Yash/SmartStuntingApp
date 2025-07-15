// lib/screens/tabs/child_data_tab.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/child.dart'; // Import model Child
import 'package:smart_stunting_app/services/child_service.dart'; // Import ChildService
import 'package:smart_stunting_app/screens/add_child_screen.dart'; // Screen untuk menambah anak
import 'package:smart_stunting_app/screens/child_detail_screen.dart'; // Screen untuk detail anak
import 'package:smart_stunting_app/screens/login_screen.dart'; // Untuk navigasi jika sesi berakhir

class ChildDataTab extends StatefulWidget {
  const ChildDataTab({super.key});

  @override
  State<ChildDataTab> createState() => _ChildDataTabState();
}

class _ChildDataTabState extends State<ChildDataTab> {
  final ChildService _childService = ChildService();
  List<Child> _children = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final fetchedChildren = await _childService.fetchChildren();
      setState(() {
        _children = fetchedChildren;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        ); // Hapus "Exception: "
        _isLoading = false;
      });
      // Jika errornya karena sesi berakhir, arahkan ke login screen
      if (e.toString().contains('Sesi berakhir')) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _deleteChild(int id) async {
    // Tampilkan dialog konfirmasi sebelum menghapus
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Data Anak'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus data anak ini?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true; // Tampilkan loading saat menghapus
      });
      try {
        final response = await _childService.deleteChild(id);
        if (response.message == 'Deleted successfully') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data anak berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchChildren(); // Muat ulang daftar anak setelah dihapus
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Gagal menghapus data anak'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onPressed: _fetchChildren,
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
          : _children
                .isEmpty // KONDISI KETIKA DATA ANAK KOSONG
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- TAMBAHAN BARU DIMULAI DI SINI ---
                  const Icon(
                    Icons.child_care, // Ikon anak
                    size: 100, // Ukuran ikon yang lebih besar
                    color: Colors.lightBlue, // Warna yang lebih cerah
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Data Anak Pengguna Baru', // Keterangan baru
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15), // Spasi setelah keterangan baru

                  // --- TAMBAHAN BARU BERAKHIR DI SINI ---
                  const Icon(
                    Icons.info_outline,
                    size: 80,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Belum ada data anak.',
                    style: TextStyle(fontSize: 20, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tambahkan data anak pertama Anda sekarang!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: () async {
                      // Navigasi ke detail anak dan refresh jika ada perubahan
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChildDetailScreen(childId: child.id),
                        ),
                      );
                      _fetchChildren(); // Muat ulang daftar setelah kembali dari detail/edit
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Icon(
                              child.jenisKelamin == 'Laki-laki'
                                  ? Icons.male
                                  : Icons.female,
                              size: 35,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.nama,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${child.umurBulan} bulan | ${child.berat} kg | ${child.tinggi} cm',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                // Anda bisa menambahkan detail lain di sini
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteChild(child.id),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddChildScreen()),
          );
          if (result == true) {
            _fetchChildren(); // Muat ulang daftar anak jika berhasil menambah
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
