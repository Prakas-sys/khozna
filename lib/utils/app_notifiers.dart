import 'package:flutter/material.dart';

/// Global notifier for the Messages tab badge count.
/// Increment this when a booking is made.
final ValueNotifier<int> messageBadgeCount = ValueNotifier<int>(0);

/// Global notifier for the Notification icon badge count.
final ValueNotifier<int> notificationBadgeCount = ValueNotifier<int>(3); // Set to 3 for demo

