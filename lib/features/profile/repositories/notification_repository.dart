import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';

class NotificationRepository {
  static final _client = Supabase.instance.client;
  static RealtimeChannel? _notificationChannel;

  /// NEW: Robust initializer for all real-time listeners
  static void initRealtimeListeners() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _notificationChannel?.unsubscribe();

    _notificationChannel = _client
        .channel('public:notifications-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            notificationBadgeCount.value += 1;

            final data = payload.newRecord;
            
            // Set the latest notification for in-app alert logic
            lastRealtimeNotification.value = data;

            if (data['type'] == 'kyc_update' ||
                (data['title'] ?? '').toString().contains('KYC')) {
              lastKycNotification.value = data;
            }
          },
        );
    _notificationChannel?.subscribe();

    _client
        .channel('public:messages-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.neq,
            column: 'sender_id',
            value: user.id,
          ),
          callback: (payload) {
            ChatRepository.fetchUnreadMessageCount();
          },
        )
        .subscribe();

    fetchUnreadNotificationCount();
    ChatRepository.fetchUnreadMessageCount();
  }

  /// Save the user's FCM Push Token
  static Future<void> saveDeviceToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }

  /// Fetch all notifications for the current user
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('notifications')
          .select('*, sender:sender_id(full_name, avatar_url, kyc_status, trust_badge, area_name, user_type)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Delete a specific notification
  static Future<void> deleteNotification(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id); // 🔐 IDOR Protection
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Delete all notifications for current user
  static Future<void> deleteAllNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('notifications').delete().eq('user_id', user.id);
      notificationBadgeCount.value = 0;
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// Mark all notifications as read for the current user
  static Future<void> markNotificationsAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
      notificationBadgeCount.value = 0;
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  /// Fetch the number of unread notifications
  static Future<void> fetchUnreadNotificationCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false)
          .count(CountOption.exact);

      notificationBadgeCount.value = response.count;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }
}
