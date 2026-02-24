import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class SecurityUtils {
  /// Checks if the device is rooted or jailbroken.
  /// This is a "Mr. Robot" style protection to prevent the app
  /// from running in compromised environments.
  static Future<bool> isDeviceCompromised() async {
    try {
      bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      bool developerMode = await FlutterJailbreakDetection.developerMode;
      
      // We consider the device compromised if it's jailbroken.
      // Developer mode is often active for power users but can be a vector.
      // For now, we mainly block jailbroken/rooted devices.
      return jailbroken;
    } catch (e) {
      // If we can't check, we err on the side of caution or allow it.
      // For now, allow to avoid blocking legitimate users on check failure.
      return false;
    }
  }
}
