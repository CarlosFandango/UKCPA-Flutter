import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
      // Create the screenshots directory if it doesn't exist
      final directory = Directory('build/screenshots');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Save screenshot to build/screenshots/ directory
      final File image = File('build/screenshots/$screenshotName.png');
      await image.writeAsBytes(screenshotBytes);
      print('📸 Screenshot saved: ${image.path}');
      return true;
    },
  );
}