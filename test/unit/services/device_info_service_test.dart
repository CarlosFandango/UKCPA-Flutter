import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/core/services/device_info_service.dart';

/// Unit tests for DeviceInfoService
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('DeviceInfoService', () {
    test('generates consistent device ID', () async {
      // Get device ID twice
      final deviceId1 = await DeviceInfoService.getDeviceId();
      final deviceId2 = await DeviceInfoService.getDeviceId();
      
      // Should be the same (cached)
      expect(deviceId1, equals(deviceId2));
      expect(deviceId1, isNotEmpty);
      expect(deviceId1.length, greaterThan(10));
    });

    test('device ID has correct format', () async {
      final deviceId = await DeviceInfoService.getDeviceId();
      
      // Should have platform prefix
      expect(deviceId, matches(RegExp(r'^[A-Za-z]+-.*')));
      expect(deviceId, isNotEmpty);
    });

    test('can clear and regenerate device ID', () async {
      final originalId = await DeviceInfoService.getDeviceId();
      
      // Clear device ID
      await DeviceInfoService.clearDeviceId();
      
      // Should not have stored ID
      final hasStored = await DeviceInfoService.hasStoredDeviceId();
      expect(hasStored, isFalse);
      
      // Generate new ID
      final newId = await DeviceInfoService.getDeviceId();
      expect(newId, isNotEmpty);
      expect(newId, isNot(equals(originalId))); // Should be different
    });

    test('device info contains required fields', () async {
      final deviceInfo = await DeviceInfoService.getDeviceInfo();
      
      expect(deviceInfo['deviceId'], isNotEmpty);
      expect(deviceInfo['platform'], isNotEmpty);
      expect(deviceInfo, isA<Map<String, dynamic>>());
    });

    test('handles errors gracefully', () async {
      // This test ensures the service doesn't crash on errors
      final deviceId = await DeviceInfoService.getDeviceId();
      expect(deviceId, isNotEmpty);
      
      final deviceInfo = await DeviceInfoService.getDeviceInfo();
      expect(deviceInfo, isNotEmpty);
    });
  });
}