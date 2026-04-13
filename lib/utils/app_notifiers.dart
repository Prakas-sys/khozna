import 'package:flutter/material.dart';

/// Global notifier for the Messages tab badge count.
final ValueNotifier<int> messageBadgeCount = ValueNotifier<int>(0);

/// Global notifier for the Notification icon badge count.
final ValueNotifier<int> notificationBadgeCount = ValueNotifier<int>(0);

/// Master Memory: A global set of IDs for houses saved by the user.
/// Every heart listens to this to stay Red/Grey across all screens! 🧠✨
final ValueNotifier<Set<String>> savedPropertiesStore =
    ValueNotifier<Set<String>>({});

void initializeBadgeSync() {
  void updateNativeBadge() {
    final total = messageBadgeCount.value + notificationBadgeCount.value;
    // Icon badge functionality temporarily disabled due to Android build incompatibility
    debugPrint("Native icon badge sync requested for total: $total");
  }

  messageBadgeCount.addListener(updateNativeBadge);
  notificationBadgeCount.addListener(updateNativeBadge);
}
