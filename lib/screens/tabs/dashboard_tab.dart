// lib/screens/tabs/dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/models/news.dart';
import 'package:smart_stunting_app/models/user.dart';
import 'package:smart_stunting_app/widgets/news_card.dart';
import 'package:smart_stunting_app/screens/news_detail_screen.dart';
import 'package:smart_stunting_app/screens/news_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_stunting_app/widgets/skeleton_news_card.dart'; // Impor widget skeleton

class DashboardTab extends StatelessWidget {
  final User? currentUser;
  final List<News> allNews;
  final Function(int) onItemTapped;
  final bool isLoadingProfile;
  final bool isLoadingNews;

  const DashboardTab({
    super.key,
    required this.currentUser,
    required this.allNews,
    required this.onItemTapped,
    required this.isLoadingProfile,
    required this.isLoadingNews,
  });

  Future<void> _launchUrl(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isLoadingProfile
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      currentUser?.name ?? 'Pengguna',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selamat datang kembali di aplikasi Smart Stunting.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
          const SizedBox(height: 30),

          // Bagian Fitur Cepat
          const Text(
            'Fitur Cepat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
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
                Icons.child_care,
                'Data Anak',
                Colors.orangeAccent,
                () {
                  onItemTapped(1);
                },
              ),
              _buildFeatureCard(
                context,
                Icons.person,
                'Profil Saya',
                Colors.greenAccent,
                () {
                  onItemTapped(2);
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          // --- BAGIAN BERITA TERBARU DIMULAI DI SINI ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Berita Terbaru',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewsListScreen(allNews: allNews),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Lihat Semua'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          const SizedBox(height: 15),
          isLoadingNews
              ? Column(
                  children: List.generate(
                    3,
                    (index) => const SkeletonNewsCard(),
                  ),
                )
              : allNews.isEmpty
              ? const Center(child: Text('Tidak ada berita yang ditemukan.'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allNews.length > 3 ? 3 : allNews.length,
                  itemBuilder: (context, index) {
                    final newsItem = allNews[index];
                    return NewsCard(
                      news: newsItem,
                      onTap: () {
                        if (newsItem.url != null && newsItem.url!.isNotEmpty) {
                          _launchUrl(newsItem.url!, context);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NewsDetailScreen(news: newsItem),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
          const SizedBox(height: 20),
        ],
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
