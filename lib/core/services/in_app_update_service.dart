import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  /// Checks Google Play Store for available app updates and prompts the user with a Flexible In-App Update flow.
  static Future<void> checkForUpdate() async {
    // In-App Update API is supported exclusively on Android via Google Play Store
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdateAvailability();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.flexibleUpdateAllowed) {
          // Perform Flexible In-App Update (background download with non-intrusive prompt)
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            // Complete the update once download finishes
            await InAppUpdate.completeFlexibleUpdate();
          }
        }
      }
    } catch (e) {
      debugPrint('InAppUpdate check skipped/failed: $e');
    }
  }
}
