import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_notifiers.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Sync Firebase User to Supabase Profiles table
  static Future<void> syncUserWithSupabase(firebase_auth.User user) async {
    try {
      await _client.rpc('sync_firebase_user', params: {
        'uid': user.uid,
        'u_phone': user.phoneNumber ?? '',
        'u_name': user.displayName ?? 'Khozna User',
      });
    } catch (e) {
      print('Sync Error: $e');
      // If RPC is not available yet, try standard insert
      try {
        await _client.from('profiles').upsert({
          'id': user.uid,
          'phone_number': user.phoneNumber,
          'full_name': user.displayName ?? 'Khozna User',
          'email': user.email,
          'avatar_url': user.photoURL,
        }, onConflict: 'id');
      } catch (e2) {
        print('Upsert Fallback Error: $e2');
      }
    }
  }

  /// Toggle saving a property for the current user.
  static Future<void> toggleSaveProperty(String propertyId) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if already saved
      final response = await _client
          .from('saved_properties')
          .select()
          .eq('user_id', user.uid)
          .eq('property_id', propertyId)
          .maybeSingle();

      if (response == null) {
        // Save it
        await _client.from('saved_properties').insert({
          'user_id': user.uid,
          'property_id': propertyId,
        });
      } else {
        // Unsave it
        await _client
            .from('saved_properties')
            .delete()
            .eq('user_id', user.uid)
            .eq('property_id', propertyId);
      }
    } catch (e) {
      print('Supabase Error: $e');
    }
  }

  /// Mark a property as booked and notify the owner.
  static Future<void> bookProperty(String propertyId, String title, String ownerId) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Update property status
      await _client
          .from('properties')
          .update({'status': 'booked'})
          .eq('id', propertyId);

      // 2. Notify the owner
      await _client.from('notifications').insert({
        'user_id': ownerId, // The owner gets the notification
        'sender_id': user.uid, // The person who booked it
        'title': 'New Booking Request! 🏠',
        'message': '${user.displayName ?? 'A user'} wants to rent your property: "$title".',
        'type': 'booking',
      });
    } catch (e) {
      print('Supabase Booking Error: $e');
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

  /// Listen for all real-time notifications for the current user.
  static void listenToUserNotifications() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.uid,
          ),
          callback: (payload) {
            // New notification for this user!
            notificationBadgeCount.value += 1;
          },
        )
        .subscribe();
  }

  /// Save the user's FCM Push Token (Digital Mailing Address)
  static Future<void> saveDeviceToken(String token) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Save it to 'fcm_token' column in profiles table
      await _client.from('profiles').update({
        'fcm_token': token,
      }).eq('id', user.uid);
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

  /// Fetch all notifications for the current user with sender profile info
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Fetch notifications and join with the profiles table for the sender_id
      final response = await _client
          .from('notifications')
          .select('*, sender:sender_id(full_name, avatar_url)')
          .eq('user_id', user.uid)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Fetch all saved properties for the current user
  static Future<List<Map<String, dynamic>>> getSavedProperties() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('saved_properties')
          .select('*, properties(*, property_images(*), profiles(full_name, avatar_url))')
          .eq('user_id', user.uid)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching saved properties: $e');
      return [];
    }
  }

  /// Delete a specific notification
  static Future<void> deleteNotification(String id) async {
    try {
      await _client.from('notifications').delete().eq('id', id);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}
