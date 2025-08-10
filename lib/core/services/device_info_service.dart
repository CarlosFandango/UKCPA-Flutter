import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for generating and managing persistent device identifiers
/// Used by the backend to associate guest baskets with specific devices
class DeviceInfoService {
  static const String _deviceIdKey = 'device_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static final Logger _logger = Logger();
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  static String? _cachedDeviceId;

  /// Get persistent device ID for this device
  /// Generates one if it doesn't exist and stores it securely
  static Future<String> getDeviceId() async {
    // Return cached value if available
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      // Try to get existing device ID from secure storage
      final existingDeviceId = await _storage.read(key: _deviceIdKey);
      if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
        _logger.d('Using existing device ID from secure storage');
        _cachedDeviceId = existingDeviceId;
        return existingDeviceId;
      }

      // Generate new device ID based on platform-specific hardware info
      final newDeviceId = await _generateDeviceId();
      
      // Store it securely
      await _storage.write(key: _deviceIdKey, value: newDeviceId);
      _cachedDeviceId = newDeviceId;
      
      _logger.i('Generated and stored new device ID: ${newDeviceId.substring(0, 8)}...');
      return newDeviceId;
    } catch (e) {
      _logger.e('Error getting device ID: $e');
      
      // Fallback: generate a temporary ID based on timestamp
      final fallbackId = _generateFallbackId();
      _cachedDeviceId = fallbackId;
      
      _logger.w('Using fallback device ID: ${fallbackId.substring(0, 8)}...');
      return fallbackId;
    }
  }

  /// Generate a device-specific identifier based on platform information
  static Future<String> _generateDeviceId() async {
    try {
      String baseString = '';
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        // Use multiple hardware identifiers for uniqueness
        baseString = [
          androidInfo.brand,
          androidInfo.model,
          androidInfo.id,
          androidInfo.hardware,
          androidInfo.bootloader,
          androidInfo.fingerprint.substring(0, 20), // Truncate for consistency
        ].join('-');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        // iOS doesn't provide hardware identifiers, use system info
        baseString = [
          iosInfo.name,
          iosInfo.systemName,
          iosInfo.model,
          iosInfo.localizedModel,
          iosInfo.identifierForVendor ?? 'unknown-vendor',
        ].join('-');
      } else {
        // Fallback for other platforms (web, desktop)
        baseString = 'generic-${Platform.operatingSystem}-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Create a SHA-256 hash of the base string for consistent length
      final bytes = utf8.encode(baseString);
      final digest = sha256.convert(bytes);
      
      // Create a readable device ID format: platform-hash
      final platform = Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : Platform.operatingSystem;
      final deviceId = '$platform-${digest.toString().substring(0, 32)}';
      
      return deviceId;
    } catch (e) {
      _logger.e('Error generating device ID: $e');
      return _generateFallbackId();
    }
  }

  /// Generate a fallback device ID when hardware info is unavailable
  static String _generateFallbackId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = Platform.operatingSystem;
    return 'fallback-$platform-$timestamp';
  }

  /// Clear stored device ID (for testing or reset purposes)
  static Future<void> clearDeviceId() async {
    try {
      await _storage.delete(key: _deviceIdKey);
      _cachedDeviceId = null;
      _logger.i('Device ID cleared');
    } catch (e) {
      _logger.e('Error clearing device ID: $e');
      rethrow;
    }
  }

  /// Get device information for debugging/support purposes
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceId = await getDeviceId();
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return {
          'deviceId': deviceId,
          'platform': 'Android',
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return {
          'deviceId': deviceId,
          'platform': 'iOS',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
        };
      } else {
        return {
          'deviceId': deviceId,
          'platform': Platform.operatingSystem,
        };
      }
    } catch (e) {
      _logger.e('Error getting device info: $e');
      return {
        'deviceId': await getDeviceId(),
        'platform': Platform.operatingSystem,
        'error': e.toString(),
      };
    }
  }

  /// Check if device ID exists in storage
  static Future<bool> hasStoredDeviceId() async {
    try {
      final deviceId = await _storage.read(key: _deviceIdKey);
      return deviceId != null && deviceId.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking for stored device ID: $e');
      return false;
    }
  }
}