import 'package:flutter/material.dart';

/// Global notifier for the Messages tab badge count.
/// Increment this when a booking is made.
final ValueNotifier<int> messageBadgeCount = ValueNotifier<int>(0);
