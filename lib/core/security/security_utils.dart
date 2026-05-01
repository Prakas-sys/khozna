import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityUtils {
  static const MethodChannel _platform = MethodChannel('khozna/security');

  // Encrypted Storage Instance (The "Vault")
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 1. Secure Screen Shield (The "Privacy Glass")
  /// Prevents screenshots and screen recordings on sensitive screens.
  /// Call with [enable] = true on Login/KYC screens.
  static Future<void> setSecure(bool enable) async {
    try {
      await _platform.invokeMethod('setSecure', enable);
    } on PlatformException catch (_) {
      // Platform doesn't support this or threw an error.
      // In production, log this silently.
    }
  }

  /// 2. Root/Jailbreak & Integrity Detection (The "Anti-Hacker" Defense)
  /// Checks if the device is rooted, an emulator, or using mock locations.
  static Future<SecurityStatus> getDeviceStatus() async {
    try {
      final bool isRooted = await SafeDevice.isJailBroken;
      final bool isRealDevice = await SafeDevice.isRealDevice;
      final bool isMockLocation = await SafeDevice.isMockLocation;

      if (isRooted) return SecurityStatus.rooted;
      if (!isRealDevice) return SecurityStatus.emulator;
      if (isMockLocation) return SecurityStatus.mockLocation;
      
      return SecurityStatus.safe;
    } catch (_) {
      // Fail open in case of detection errors to avoid blocking real users
      return SecurityStatus.safe;
    }
  }

  /// Legacy method for compatibility
  static Future<bool> isDeviceCompromised() async {
    final status = await getDeviceStatus();
    return status != SecurityStatus.safe;
  }

  /// 3. Secure Storage Methods (The "Vault")
  /// Use these instead of SharedPreferences for sensitive data like tokens.

  static Future<void> writeSecurely(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> readSecurely(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> deleteSecurely(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> deleteAllSecurely() async {
    await _storage.deleteAll();
  }

  /// 4. Input Sanitization (The "Clean Gate")
  /// Strip dangerous characters before sending to the database.
  /// Use on ALL user-provided text inputs (titles, descriptions, messages).
  static String sanitizeInput(String input, {int maxLength = 500}) {
    final clean = input
        .trim()
        .replaceAll(RegExp('[<>"\';\\\\]'), '') // Strip XSS/SQL injection chars
        .replaceAll(RegExp(r'\s+'), ' '); // Collapse whitespace
    return clean.length > maxLength ? clean.substring(0, maxLength) : clean;
  }

  /// 5. Phone Number Masking (The "Privacy Blur")
  /// Use when displaying a user's phone number to others.
  /// Example: 9801234567 → 980****567
  static String maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
  }

  /// 6. Email Masking
  /// Example: john@gmail.com → jo***@gmail.com
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].length < 3) return email;
    return '${parts[0].substring(0, 2)}***@${parts[1]}';
  }

  /// 7. Nepal Phone Validation
  /// Validates that a phone number is a valid Nepali mobile number.
  static bool isValidNepalPhone(String phone) {
    return RegExp(r'^(97|98)\d{8}$').hasMatch(phone.trim());
  }
}

enum SecurityStatus { safe, rooted, emulator, mockLocation }
