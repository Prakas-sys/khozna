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

  // ==========================================
  // OWNER DASHBOARD METHODS
  // ==========================================

  /// Fetch overview statistics for the Owner Dashboard
  static Future<Map<String, int>> getOwnerStats() async {
    try {
      final userCount = await _client.from('profiles').select().count(CountOption.exact);
      final propertyCount = await _client.from('properties').select().count(CountOption.exact);
      final pendingKycCount = await _client
          .from('kyc_verifications')
          .select()
          .eq('status', 'pending')
          .count(CountOption.exact);
      
      final bookingCount = await _client
          .from('properties')
          .select()
          .eq('status', 'booked')
          .count(CountOption.exact);

      return {
        'totalUsers': userCount.count,
        'totalProperties': propertyCount.count,
        'pendingKyc': pendingKycCount.count,
        'activeBookings': bookingCount.count,
      };
    } catch (e) {
      print('Error fetching owner stats: $e');
      return {'totalUsers': 0, 'totalProperties': 0, 'pendingKyc': 0, 'activeBookings': 0};
    }
  }

  /// Fetch all pending KYC verifications
  static Future<List<Map<String, dynamic>>> getPendingKycs() async {
    try {
      return await _client
          .from('kyc_verifications')
          .select()
          .eq('status', 'pending')
          .order('created_at');
    } catch (e) {
      print('Error fetching pending KYCs: $e');
      return [];
    }
  }

  /// Update KYC status (Approve/Reject)
  static Future<void> updateKycStatus(String kycId, String userId, String status, {String? reason}) async {
    try {
      await _client.from('kyc_verifications').update({
        'status': status,
        'rejection_reason': reason,
      }).eq('id', kycId);

      final String profileStatus = status == 'verified' ? 'verified' : 'rejected';
      await _client.from('profiles').update({
        'kyc_status': profileStatus,
      }).eq('id', userId);

      await _client.from('notifications').insert({
        'user_id': userId,
        'title': status == 'verified' ? 'KYC Approved! ✅' : 'KYC Rejected ❌',
        'message': status == 'verified' 
            ? 'Your identity has been verified. You can now post properties.'
            : 'Your KYC was rejected. Reason: ${reason ?? "Invalid documents"}. Please try again.',
        'type': 'kyc_update',
      });
    } catch (e) {
      print('Error updating KYC status: $e');
      rethrow;
    }
  }

  /// Fetch all properties for moderation
  static Future<List<Map<String, dynamic>>> getAllPropertiesAdmin() async {
    try {
      return await _client.from('properties').select('*, profiles(full_name)').order('created_at', ascending: false);
    } catch (e) {
      print('Error fetching properties for admin: $e');
      return [];
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
              }
            }
          },
        )
        .subscribe();
  }

  /// Save the user's FCM Push Token (Digital Mailing Address)
  static Future<void> saveDeviceToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Save it to 'fcm_token' column in profiles table
      await _client.from('profiles').update({
        'fcm_token': token,
      }).eq('id', user.id);
    } catch (e) {
      print('Error saving FCM Token: $e');
    }
  }

  /// OWNER ONLY: Listen for new KYC submissions across the whole platform
  static void listenToOwnerAlerts(Function onNewEvent) {
    _client
        .channel('owner-alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'kyc_verifications',
          callback: (payload) {
            // New KYC submitted!
            notificationBadgeCount.value += 1;
            onNewEvent(); // Trigger UI refresh in Dashboard
          },
        )
        .subscribe();
  }
}
