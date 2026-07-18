import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:khozna/core/models/chat_model.dart';

/// Global notifier for the Messages tab badge count.
final ValueNotifier<int> messageBadgeCount = ValueNotifier<int>(0);

/// Global notifier for the Notification icon badge count.
final ValueNotifier<int> notificationBadgeCount = ValueNotifier<int>(0);

/// Global notifier for the current location name.
final ValueNotifier<String> currentLocationName =
    ValueNotifier<String>('Kirtipur, Nepal');

/// Master Memory: A global set of IDs for houses saved by the user.
/// Every heart listens to this to stay Red/Grey across all screens! 🧠✨
final ValueNotifier<Set<String>> savedPropertiesStore =
    ValueNotifier<Set<String>>({});

/// Master Memory: A global set of IDs for houses currently booked/pending by the user.
/// Used to instantly show "Pending" status in Property Details. 🧠✨
final ValueNotifier<Set<String>> bookedPropertiesStore =
    ValueNotifier<Set<String>>({});

void initializeBadgeSync() {
  debugPrint('Badge sync initialized (In-app only)');
}

/// Cache for Home Screen sections to enable "offline" viewing of last known data.
final ValueNotifier<Map<int, List<Map<String, dynamic>>>> homeSectionCache =
    ValueNotifier<Map<int, List<Map<String, dynamic>>>>({});

/// Cache for Messages Screen to enable instant loading.
final ValueNotifier<List<ChatConversation>?> chatListCache =
    ValueNotifier<List<ChatConversation>?>(null);

/// Cache for Profile Screen to enable instant loading.
final ValueNotifier<Map<String, dynamic>?> profileCache =
    ValueNotifier<Map<String, dynamic>?>(null);

/// Global notifier for real-time KYC status updates
/// Used to trigger Success/Rejection popups across the app.
final ValueNotifier<Map<String, dynamic>?> lastKycNotification =
    ValueNotifier<Map<String, dynamic>?>(null);

/// Global notifier for the absolute latest notification received
/// Used to show a "Toast" or "Snackbar" instantly when an event occurs.
final ValueNotifier<Map<String, dynamic>?> lastRealtimeNotification =
    ValueNotifier<Map<String, dynamic>?>(null);

/// Global notifier to trigger a refresh of listings/reels across screens.
final ValueNotifier<int> refreshTrigger = ValueNotifier<int>(0);

/// Global notifier to track whether the Reels tab is currently visible.
/// Used to pause/resume video playback when the user switches tabs.
final ValueNotifier<bool> reelsTabActive = ValueNotifier<bool>(false);

