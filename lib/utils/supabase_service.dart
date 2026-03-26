import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_notifiers.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Sync Supabase User to Profiles table
  static Future<void> syncUserWithSupabase(User user) async {
    try {
      final phone = user.phone;
      final metadata = user.userMetadata ?? {};
      final String name = metadata['full_name'] ?? metadata['name'] ?? 'Khozna User';
      final String? avatar = metadata['avatar_url'] ?? metadata['picture'];

      await _client.from('profiles').upsert({
        'id': user.id,
        'phone_number': phone,
        'full_name': name,
        'email': user.email,
        'avatar_url': avatar,
      }, onConflict: 'id');
    } catch (e) {
      print('Sync Error: $e');
    }
  }

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
          'user_id': user.uid,
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

  /// Mark a property as booked and notify the owner.
  static Future<void> bookProperty(String propertyId, String title, String ownerId) async {
    final user = _client.auth.currentUser;
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
        'sender_id': user.id, // The person who booked it
        'title': 'New Booking Request! 🏠',
        'message': '${user.userMetadata?['full_name'] ?? 'A user'} wants to rent your property: "$title".',
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

  /// Handles Google Sign-In using Supabase.
  static Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
    } catch (e) {
      print('Supabase Google Sign-In Error: $e');
      rethrow;
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

  /// Fetch all users for management
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      return await _client.from('profiles').select().order('created_at', ascending: false);
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Search users by name or phone
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      return await _client
          .from('profiles')
          .select()
          .or('full_name.ilike.%$query%,phone_number.ilike.%$query%')
          .order('created_at', ascending: false);
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Listen for all real-time notifications for the current user.
  static void listenToUserNotifications() {
    final user = _client.auth.currentUser;
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
            value: user.id,
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

  /// Fetch all notifications for the current user with sender profile info
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      // Fetch notifications and join with the profiles table for the sender_id
      final response = await _client
          .from('notifications')
          .select('*, sender:sender_id(full_name, avatar_url)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Fetch all saved properties for the current user
  static Future<List<Map<String, dynamic>>> getSavedProperties() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('saved_properties')
          .select('*, properties(*, property_images(*), profiles(full_name, avatar_url))')
          .eq('user_id', user.id)
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

  // ==========================================
  // MESSAGING & CHAT METHODS
  // ==========================================

  /// Fetch all chat threads for the current user
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      // Fetch chats where participants array contains use.id
      final response = await _client
          .from('chats')
          .select('*, profiles!participants(id, full_name, avatar_url)')
          .contains('participants', [user.id])
          .order('updated_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  /// Get or create a chat thread with another user
  static Future<String> getOrCreateChat(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 1. Check if chat already exists
      final existing = await _client
          .from('chats')
          .select()
          .contains('participants', [user.id, otherUserId])
          .maybeSingle();

      if (existing != null) return existing['id'];

      // 2. Create new chat
      final created = await _client
          .from('chats')
          .insert({
            'participants': [user.id, otherUserId],
          })
          .select()
          .single();

      return created['id'];
    } catch (e) {
      print('Error getting/creating chat: $e');
      rethrow;
    }
  }

  /// Get real-time stream of messages for a chat
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Send a message in a chat
  static Future<void> sendMessage(String chatId, String text) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': user.id,
        'text': text,
      });

      // Update the chat's updated_at timestamp for sorting
      await _client
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}
