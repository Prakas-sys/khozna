import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_notifiers.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Toggle saving a property for the current user.
  static Future<void> toggleSaveProperty(String propertyId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Check if already saved
      final response = await _client
          .from('saved_properties')
          .select()
          .eq('user_id', user.id)
          .eq('property_id', propertyId)
          .maybeSingle();

      if (response == null) {
        // Save it
        await _client.from('saved_properties').insert({
          'user_id': user.id,
          'property_id': propertyId,
        });
      } else {
        // Unsave it
        await _client
            .from('saved_properties')
            .delete()
            .eq('user_id', user.id)
            .eq('property_id', propertyId);
      }
    } catch (e) {
      print('Supabase Error: $e');
    }
  }

  /// Mark a property as booked.
  /// In a real app, this would trigger a Database Webhook or Edge Function.
  static Future<void> bookProperty(String propertyId, String title) async {
    try {
      await _client
          .from('properties')
          .update({'status': 'booked'})
          .eq('id', propertyId);
      
      // The "Magic": In a real setup, Supabase would now send notifications
      // to all users who have this propertyId in 'saved_properties'.
    } catch (e) {
      print('Supabase Error: $e');
    }
  }

  /// Listen for real-time booking notifications.
  /// This simulates receiving a push notification for a saved property.
  static void listenToBookingNotifications() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _client
        .channel('public:properties')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'properties',
          callback: (payload) async {
            final String propertyId = payload.newRecord['id'];
            final String status = payload.newRecord['status'];

            if (status == 'booked') {
              // Check if the current user has saved this property
              final saved = await _client
                  .from('saved_properties')
                  .select()
                  .eq('user_id', user.id)
                  .eq('property_id', propertyId)
                  .maybeSingle();

              if (saved != null) {
                // Trigger local notification/badge
                notificationBadgeCount.value += 1;
                // You could also show a SnackBar or Toast here
              }
            }
          },
        )
        .subscribe();
  }
}
