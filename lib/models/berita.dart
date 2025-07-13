// lib/models/berita.dart
class Berita {
  final int id;
  final String title;
  final String content;
  final String url;
  final String? image; // Image bisa null

  Berita({
    required this.id,
    required this.title,
    required this.content,
    required this.url,
    this.image,
  });

  factory Berita.fromJson(Map<String, dynamic> json) {
    return Berita(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      url: json['url'],
      image: json['image'], // Image bisa null dari API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'url': url,
      'image': image,
    };
  }
}
