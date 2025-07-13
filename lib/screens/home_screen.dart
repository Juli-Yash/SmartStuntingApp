// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/screens/tabs/child_data_tab.dart'; // Menggunakan tab yang spesifik
import 'package:smart_stunting_app/screens/tabs/profile_tab.dart'; // Menggunakan tab yang spesifik
import 'package:smart_stunting_app/services/auth_service.dart';
import 'package:smart_stunting_app/models/user.dart';
import 'package:smart_stunting_app/screens/login_screen.dart';
import 'package:smart_stunting_app/models/berita.dart';
import 'package:smart_stunting_app/services/berita_service.dart';
import 'package:smart_stunting_app/screens/berita_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? _currentUser;
  final AuthService _authService = AuthService();
  final BeritaService _beritaService = BeritaService();
  List<Berita> _latestBerita = [];
  bool _isBeritaLoading = true;
  String _beritaErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchLatestBerita();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _authService.fetchUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error fetching current user: $e');
      _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _fetchLatestBerita() async {
    setState(() {
      _isBeritaLoading = true;
      _beritaErrorMessage = '';
    });
    try {
      final berita = await _beritaService.fetchAllBerita();
      setState(() {
        _latestBerita = berita.take(3).toList();
      });
    } catch (e) {
      setState(() {
        _beritaErrorMessage = 'Gagal memuat berita: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isBeritaLoading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak dapat membuka link: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN PENTING DI SINI: Urutan Widget Options untuk Tab Bar ---
    final List<Widget> _widgetOptions = <Widget>[
      // Index 0: Home/Dashboard Content
      SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${_currentUser?.name ?? 'Pengguna'}!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Selamat datang kembali di aplikasi Smart Stunting.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),

            // Bagian Fitur Cepat
            Text(
              'Fitur Cepat',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFeatureCard(
                  context,
                  Icons.child_care, // Menggunakan ikon yang lebih relevan
                  'Data Anak',
                  Colors.orangeAccent,
                  () {
                    // Langsung pindah ke tab Data Anak (index 1)
                    _onItemTapped(1);
                  },
                ),
                _buildFeatureCard(
                  context,
                  Icons.person,
                  'Profil Saya',
                  Colors.greenAccent,
                  () {
                    // Langsung pindah ke tab Profil (index 2)
                    _onItemTapped(2);
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Bagian Berita Terbaru (tetap sama)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Berita Terbaru',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BeritaListScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _isBeritaLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _beritaErrorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _beritaErrorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : _latestBerita.isEmpty
                ? const Center(child: Text('Belum ada berita terbaru.'))
                : Column(
                    children: _latestBerita.map((berita) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _launchURL(berita.url),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (berita.image != null &&
                                    berita.image!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      berita.image!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.grey[400],
                                                size: 30,
                                              ),
                                            );
                                          },
                                    ),
                                  )
                                else
                                  Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.newspaper,
                                      color: Colors.grey[400],
                                      size: 40,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        berita.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        berita.content,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 30),
            // <<< DIHAPUS: Tombol LOGOUT sudah dipindahkan ke ProfileTab >>>
          ],
        ),
      ),
      // Index 1: Data Anak Tab
      const ChildDataTab(),
      // Index 2: Profil Tab
      ProfileTab(
        onProfileUpdated: () {
          _fetchCurrentUser(); // Refresh user data after profile update
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Stunting App'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // --- PERUBAHAN PENTING DI SINI: Urutan BottomNavigationBarItem ---
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care),
            label: 'Data Anak',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          // --- AKHIR PERUBAHAN ---
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor:
            Colors.grey, // Menambahkan warna untuk item tidak terpilih
        showUnselectedLabels:
            true, // Memastikan label tidak terpilih juga muncul
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
