import 'package:flutter/material.dart';
import '../core/utils/image_loader.dart';

/// Test widget to verify image loading functionality
class ImageTestWidget extends StatelessWidget {
  const ImageTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const testImageUrls = [
      'https://picsum.photos/600/300',
      'https://picsum.photos/300/200',
      'https://picsum.photos/400/250',
      null, // Test null handling
      '', // Test empty string handling
      'https://invalid-url-that-should-fail.com/image.jpg', // Test error handling
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Loading Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () async {
              await ImageLoader.clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image cache cleared')),
              );
            },
            tooltip: 'Clear Cache',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testImageUrls.length,
        itemBuilder: (context, index) {
          final url = testImageUrls[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test ${index + 1}: ${url ?? 'null URL'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  // Test different image loading methods
                  Row(
                    children: [
                      // Course card style
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Course Card Style:'),
                            const SizedBox(height: 4),
                            ImageLoader.forCourseCard(
                              imageUrl: url,
                              width: double.infinity,
                              height: 120,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Thumbnail style
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Thumbnail Style:'),
                            const SizedBox(height: 4),
                            ImageLoader.forThumbnail(
                              imageUrl: url,
                              width: double.infinity,
                              height: 80,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Avatar style
                  Row(
                    children: [
                      const Text('Avatar Style: '),
                      const SizedBox(width: 8),
                      ImageLoader.forAvatar(
                        imageUrl: url,
                        size: 48,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}