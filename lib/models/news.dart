// lib/models/news.dart
class News {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final String content;
  final String? url;

  News({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.content,
    this.url,
  });

  // Factory constructor untuk membuat objek News dari JSON
  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['url'] as String,
      title: json['title'] as String? ?? 'Judul Tidak Tersedia',
      imageUrl:
          json['urlToImage'] as String? ?? 'https://via.placeholder.com/150',
      description:
          json['description'] as String? ?? 'Deskripsi tidak tersedia.',
      content: json['content'] as String? ?? 'Konten tidak tersedia.',
      url: json['url'] as String?,
    );
  }
}
