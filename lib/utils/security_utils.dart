import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityUtils {
  static const MethodChannel _platform = MethodChannel('khozna/security');
  
  // Encrypted Storage Instance (The "Vault")
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
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

  /// 2. Root/Jailbreak Detection (The "Mr. Robot" Defense)
  /// Checks if the device is rooted or jailbroken to prevent running in compromised environments.
  static Future<bool> isDeviceCompromised() async {
    try {
      // SafeDevice checks multiple factors: rooted, real device, mock location
      bool isRooted = await SafeDevice.isJailBroken;
      bool isRealDevice = await SafeDevice.isRealDevice;
      
      // We consider the device compromised if it's rooted OR it's an emulator (optional)
      // For now, only block rooted/jailbroken devices.
      return isRooted;
    } catch (e) {
      // If detection fails, assume safe to avoid blocking legitimate users due to errors.
      return false; 
    }
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
}
