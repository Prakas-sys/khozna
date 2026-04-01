import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

/// Global notifier for the Messages tab badge count.
final ValueNotifier<int> messageBadgeCount = ValueNotifier<int>(0);

/// Global notifier for the Notification icon badge count.
final ValueNotifier<int> notificationBadgeCount = ValueNotifier<int>(0);

void initializeBadgeSync() {
  void updateNativeBadge() {
    final total = messageBadgeCount.value + notificationBadgeCount.value;
    if (total > 0) {
      FlutterAppBadger.updateBadgeCount(total);
    } else {
      FlutterAppBadger.removeBadge();
    }
  }

  messageBadgeCount.addListener(updateNativeBadge);
  notificationBadgeCount.addListener(updateNativeBadge);
}
