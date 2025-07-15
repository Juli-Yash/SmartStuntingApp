// lib/screens/berita_list_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/berita.dart';
import 'package:smart_stunting_app/services/berita_service.dart';
import 'package:url_launcher/url_launcher.dart'; // Untuk membuka URL berita
import 'package:smart_stunting_app/screens/login_screen.dart'; // Untuk redirect jika unauthorized

class BeritaListScreen extends StatefulWidget {
  const BeritaListScreen({super.key});

  @override
  State<BeritaListScreen> createState() => _BeritaListScreenState();
}

class _BeritaListScreenState extends State<BeritaListScreen> {
  final BeritaService _beritaService = BeritaService();
  List<Berita> _beritaList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // !!! PENTING !!!
  // Sesuaikan BASE_IMAGE_URL ini dengan path yang BENAR di server Anda
  // Misalnya:
  // - 'http://147.93.106.201/storage/' (umum untuk Laravel/Lumen storage)
  // - 'http://147.93.106.201/public/images/' (jika gambar ada di public folder)
  // - 'http://147.93.106.201/uploads/' (jika Anda menggunakan folder 'uploads')
  // Coba cek path gambar di browser setelah Anda mendapatkan response API
  static const String BASE_IMAGE_URL =
      'http://147.93.106.201/storage/'; // <-- GANTI INI

  @override
  void initState() {
    super.initState();
    _fetchBerita();
  }

  Future<void> _fetchBerita() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final berita = await _beritaService.fetchAllBerita();
      setState(() {
        _beritaList = berita;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        ); // Hapus "Exception: "
      });
      // Redirect ke login jika sesi berakhir
      if (e.toString().contains('Sesi berakhir') ||
          e.toString().contains('Unauthorized')) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    // Tambahkan debug print untuk URL yang akan diluncurkan
    print('Attempting to launch URL: $url');
    final uri = Uri.tryParse(
      url,
    ); // Gunakan tryParse untuk menghindari error jika URL tidak valid

    if (uri == null ||
        !uri.hasScheme ||
        (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https'))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('URL tidak valid: $url')));
      print('Invalid URL scheme or format: $url');
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat membuka link: $url. Pastikan aplikasi browser terinstal.',
          ),
        ),
      );
      print('Could not launch URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Berita Terbaru'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                      onPressed: _fetchBerita,
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
          : _beritaList.isEmpty
          ? const Center(child: Text('Belum ada berita yang tersedia.'))
          : RefreshIndicator(
              onRefresh: _fetchBerita,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _beritaList.length,
                itemBuilder: (context, index) {
                  final berita = _beritaList[index];

                  // Bangun URL gambar lengkap
                  final String? fullImageUrl =
                      (berita.image != null && berita.image!.isNotEmpty)
                      ? BASE_IMAGE_URL + berita.image!
                      : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: () =>
                          _launchURL(berita.url), // Seluruh Card bisa diklik
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fullImageUrl !=
                                null) // Tampilkan gambar jika URL lengkap ada
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  fullImageUrl, // Gunakan URL gambar yang lengkap di sini
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          height: 180,
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      'Error loading image for URL: $fullImageUrl - Error: $error',
                                    );
                                    return Container(
                                      height: 180,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey[400],
                                        size: 50,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (fullImageUrl !=
                                null) // Hanya berikan SizedBox jika ada gambar
                              const SizedBox(height: 12),
                            Text(
                              berita.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              berita.content,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.bottomRight,
                              // Teks "Baca Selengkapnya" adalah bagian dari Card yang sudah bisa diklik
                              // Jika Anda ingin hanya teks ini yang clickable, Anda perlu membungkusnya dengan GestureDetector atau InkWell terpisah.
                              // Namun, saat ini seluruh card sudah clickable.
                              child: Text(
                                'Baca Selengkapnya',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
