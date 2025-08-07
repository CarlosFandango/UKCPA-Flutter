import 'package:flutter/material.dart';
import '../core/utils/image_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Debug screen to test image loading issues
class ImageDebugScreen extends StatefulWidget {
  const ImageDebugScreen({super.key});

  @override
  State<ImageDebugScreen> createState() => _ImageDebugScreenState();
}

class _ImageDebugScreenState extends State<ImageDebugScreen> {
  final List<String> testUrls = [
    // Mix of working and failing URLs to test our error handling
    'https://abh.ai/cats/600/300', // Basic picsum (sometimes works)
    'https://httpbin.org/image/jpeg', // Usually reliable
    'https://abh.ai/cats/600/300/?random=18', // Unreliable picsum
    'https://via.placeholder.com/600x300/0000FF/FFFFFF?text=Test', // Reliable placeholder
    'https://nonexistent-domain-12345.com/image.jpg', // DNS failure test
    'https://httpbin.org/status/404', // 404 error test
    'https://httpbin.org/delay/30', // Timeout test (30s delay)
    'https://via.placeholder.com/320x240/FF0000/FFFFFF?text=Fallback', // Reliable fallback
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Loading Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Testing Image Loading',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Test with our ImageLoader
            const Text('Using ImageLoader.forCourseCard:',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: testUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 300,
                      height: 200,
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: ImageLoader.forCourseCard(
                                imageUrl: testUrls[index],
                                width: 300,
                                height: 150,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'URL ${index + 1}',
                                style: const TextStyle(fontSize: 12),
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

            const SizedBox(height: 32),

            // Test with direct CachedNetworkImage
            const Text('Using CachedNetworkImage directly:',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: testUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 300,
                      height: 200,
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: CachedNetworkImage(
                                imageUrl: testUrls[index],
                                width: 300,
                                height: 150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  print('Image error for $url: $error');
                                  return Container(
                                    color: Colors.red[100],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error,
                                            color: Colors.red),
                                        Text('Error: $error'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Direct ${index + 1}',
                                style: const TextStyle(fontSize: 12),
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

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Test individual URL
                _testSingleUrl(testUrls[0]);
              },
              child: const Text('Test First URL'),
            ),
          ],
        ),
      ),
    );
  }

  void _testSingleUrl(String url) {
    print('Testing URL: $url');

    // Show dialog with single image
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Single Image Test'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) {
              print('Loading: $url');
              return const Center(child: CircularProgressIndicator());
            },
            errorWidget: (context, url, error) {
              print('Error loading $url: $error');
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  Text('Failed to load: $error'),
                  Text('URL: $url', style: const TextStyle(fontSize: 12)),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
