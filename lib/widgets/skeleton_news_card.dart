import 'package:flutter/material.dart';

class SkeletonNewsCard extends StatelessWidget {
  const SkeletonNewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder untuk gambar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300], // Warna abu-abu
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder untuk judul
                  Container(
                    height: 16,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  // Placeholder untuk deskripsi
                  Container(
                    height: 14,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  Container(height: 14, color: Colors.grey[300]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
