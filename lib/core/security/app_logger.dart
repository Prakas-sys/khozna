import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AppLogger: Centralized secure logging for auditing and debugging.
/// Monitors auth events, API errors, and suspicious behavior without leaking PII.
class AppLogger {
  /// Log an authentication attempt
  static void logAuthAttempt({
    required String method,
    required bool success,
    String? userId,
    String? error,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final status = success ? "SUCCESS" : "FAILED";
    debugPrint(
      '[AUTH_LOG] [$timestamp] Method: $method | Status: $status | User: ${userId ?? 'Unknown'} | Error: ${error ?? 'None'}',
    );
    // In production, this could send data to Datadog, Sentry, or a secure Supabase logging table
  }

  /// Log an API or Database error
  static void logApiError({
    required String endpoint,
    required String error,
    String? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint(
      '[API_ERROR] [$timestamp] Endpoint: $endpoint | Error: $error | Context: ${context ?? 'None'}',
    );
  }

  /// Log suspicious traffic or potential IDOR / Rate limit hits
  static void logSuspiciousActivity({
    required String event,
    required String details,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint(
      '[SECURITY_ALERT] [$timestamp] Event: $event | User: ${user?.id ?? 'Anonymous'} | Details: $details',
    );
  }

  /// General operational logging
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] ${DateTime.now().toIso8601String()} - $message');
    }
  }
}
