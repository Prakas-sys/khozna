import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_notifiers.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;
  static RealtimeChannel? _notificationChannel;
  static RealtimeChannel? _ownerKycChannel;
  static RealtimeChannel? _ownerReportChannel;

  /// Current logged-in user's ID
  static String get currentUserId => _client.auth.currentUser?.id ?? '';

  /// Fetch a user's profile by ID
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching profile $userId: $e');
      return null;
    }
  }

  /// Sync Supabase User to Profiles table
  static Future<void> syncUserWithSupabase(User user) async {
    try {
      final phone = user.phone;
      final metadata = user.userMetadata ?? {};
      final String name =
          metadata['full_name'] ?? metadata['name'] ?? 'Khozna User';
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

  /// Initial Load for Master Memory: Fetch all IDs the user has saved.
  static Future<void> fetchSavedPropertyIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('saved_properties')
          .select('property_id')
          .eq('user_id', user.id);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );
      final set = data.map((e) => e['property_id'].toString()).toSet();
      savedPropertiesStore.value = set;
      debugPrint(
        '--- [DATABASE] Master Memory Loaded: ${set.length} saved houses ---',
      );
    } catch (e) {
      print('Error fetching saved IDs: $e');
    }
  }

  /// Toggle saving a property AND updating Master Memory instantly!
  static Future<void> toggleSaveProperty(String propertyId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // 1. Instantly update the Master Memory (Optimistic UX)
    final current = Set<String>.from(savedPropertiesStore.value);
    final isCurrentlySaved = current.contains(propertyId);

    if (isCurrentlySaved) {
      current.remove(propertyId);
    } else {
      current.add(propertyId);
    }
    savedPropertiesStore.value = current;

    // 2. Perform the database sync in the background
    try {
      if (isCurrentlySaved) {
        await _client
            .from('saved_properties')
            .delete()
            .eq('user_id', user.id)
            .eq('property_id', propertyId);
      } else {
        await _client.from('saved_properties').insert({
          'user_id': user.id,
          'property_id': propertyId,
        });
      }
    } catch (e) {
      // 3. If it fails, revert the Memory back to original State
      print('Database Error: $e');
      final reverted = Set<String>.from(savedPropertiesStore.value);
      if (isCurrentlySaved) {
        reverted.add(propertyId);
      } else {
        reverted.remove(propertyId);
      }
      savedPropertiesStore.value = reverted;
    }
  }

  /// Guest requests to book a property — sets status to pending_approval
  /// and sends a booking_request notification to the owner with Approve/Reject metadata.
  static Future<void> bookProperty(
    String propertyId,
    String title,
    String ownerId,
  ) async {
    // This is the old simple booking method. We'll keep it for compatibility 
    // but the new BookingRequestScreen uses createBookingRequest below.
    final user = _client.auth.currentUser;
    if (user == null) return;
    await createBookingRequest(
      propertyId: propertyId,
      propertyTitle: title,
      ownerId: ownerId,
      moveInDate: DateTime.now().add(const Duration(days: 7)),
      durationMonths: 1,
      guestCount: 1,
      purpose: 'other',
      message: 'Interested in booking this property.',
    );
  }

  /// Create a formal booking request in the 'bookings' table
  static Future<void> createBookingRequest({
    required String propertyId,
    required String propertyTitle,
    required String ownerId,
    required DateTime moveInDate,
    required int durationMonths,
    required int guestCount,
    required String purpose,
    required String message,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Create the booking record
      await _client.from('bookings').insert({
        'property_id': propertyId,
        'guest_id': user.id,
        'owner_id': ownerId,
        'property_title': propertyTitle,
        'move_in_date': moveInDate.toIso8601String(),
        'duration_months': durationMonths,
        'guests_count': guestCount,
        'purpose': purpose,
        'message': message,
        'status': 'pending',
      });

      // 2. Update property status (legacy compatibility)
      await _client
          .from('properties')
          .update({'status': 'pending_approval'})
          .eq('id', propertyId);

      // 3. Notify owner
      final String name = user.userMetadata?['full_name'] ?? 'A user';
      await _client.from('notifications').insert({
        'user_id': ownerId,
        'sender_id': user.id,
        'title': '🏠 New Booking Request',
        'message': '$name wants to rent "$propertyTitle"\nMove-in: ${moveInDate.day}/${moveInDate.month}',
        'type': 'booking_request',
        'property_id': propertyId,
        'requester_id': user.id,
      });

      // Note: badge count only increments for the RECIPIENT (owner), not the sender (guest)
    } catch (e) {
      print('Booking Request Error: $e');
      rethrow;
    }
  }

  /// Owner approves a booking request.
  /// - Sets property status to 'booked'
  /// - Notifies the guest that their booking was approved
  static Future<void> approveBooking({
    required String propertyId,
    required String propertyTitle,
    required String requesterId,
    required String ownerName,
    required String notificationId,
  }) async {
    try {
      // 1. Mark property as officially booked
      await _client
          .from('properties')
          .update({'status': 'booked'})
          .eq('id', propertyId);

      // 2. Update booking record if it exists
      await _client
          .from('bookings')
          .update({
            'status': 'confirmed',
            'confirmed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('property_id', propertyId)
          .eq('guest_id', requesterId)
          .eq('status', 'pending');

      // 3. Notify the guest
      await _client.from('notifications').insert({
        'user_id': requesterId,
        'sender_id': _client.auth.currentUser?.id,
        'title': '✅ Booking Approved!',
        'message': '$ownerName approved your booking request for "$propertyTitle". Contact the owner to confirm move-in details.',
        'type': 'booking_approved',
        'property_id': propertyId,
      });

      // 4. Delete the original booking_request notification (action done)
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      print('Approve booking error: $e');
      rethrow;
    }
  }

  /// Owner rejects a booking request.
  /// - Sets property status back to 'available'
  /// - Notifies the guest that their booking was not accepted
  static Future<void> rejectBooking({
    required String propertyId,
    required String propertyTitle,
    required String requesterId,
    required String notificationId,
    String? reason,
  }) async {
    try {
      // 1. Release the property back to available
      await _client
          .from('properties')
          .update({'status': 'available'})
          .eq('id', propertyId);

      // 2. Update booking record if it exists
      await _client
          .from('bookings')
          .update({
            'status': 'rejected',
            'reject_reason': reason ?? 'Owner declined the request.',
          })
          .eq('property_id', propertyId)
          .eq('guest_id', requesterId)
          .eq('status', 'pending');

      // 3. Notify the guest
      await _client.from('notifications').insert({
        'user_id': requesterId,
        'sender_id': _client.auth.currentUser?.id,
        'title': '❌ Booking Not Accepted',
        'message': 'Your booking request for "$propertyTitle" was not accepted. ${reason ?? ""}',
        'type': 'booking_rejected',
        'property_id': propertyId,
      });

      // 4. Delete the original booking_request notification
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      print('Reject booking error: $e');
      rethrow;
    }
  }

  /// Cancel a booking and make the property available again
  static Future<void> cancelBooking(String propertyId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('properties')
          .update({'status': 'available'})
          .eq('id', propertyId);

      // Property released back to available - no badge bump needed here
    } catch (e) {
      print('Supabase Cancel Booking Error: $e');
      rethrow;
    }
  }

  // ==========================================
  // OWNER DASHBOARD METHODS
  // ==========================================

  /// Fetch overview statistics for the Owner Dashboard
  static Future<Map<String, int>> getOwnerStats() async {
    try {
      final userCount = await _client
          .from('profiles')
          .select()
          .count(CountOption.exact);
      final propertyCount = await _client
          .from('properties')
          .select()
          .count(CountOption.exact);
      final pendingKycCount = await _client
          .from('kyc_verifications')
          .select()
          .eq('status', 'pending')
          .count(CountOption.exact);

      final reportCount = await _client
          .from('user_reports')
          .select()
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
        'pendingReports': reportCount.count,
        'activeBookings': bookingCount.count,
      };
    } catch (e) {
      print('Error fetching owner stats: $e');
      return {
        'totalUsers': 0,
        'totalProperties': 0,
        'pendingKyc': 0,
        'pendingReports': 0,
        'activeBookings': 0,
      };
    }
  }

  /// Handles Google Sign-In using Supabase (Native / Token based).
  /// This fixes the branding issue (removes "supabase" text) and the redirect issue.
  static Future<void> signInWithGoogleNative({
    required String idToken,
    String? accessToken,
  }) async {
    try {
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      print('Supabase Native Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Handles Google Sign-In using Supabase (Web/OAuth - Fallback).
  static Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.khozna.khozna://login-callback/',
      );
    } catch (e) {
      print('Supabase Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Handles Facebook Sign-In using Supabase.
  static Future<void> signInWithFacebook() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'com.khozna.khozna://login-callback/',
      );
    } catch (e) {
      print('Supabase Facebook Sign-In Error: $e');
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
  static Future<void> updateKycStatus(
    String kycId,
    String userId,
    String status, {
    String? reason,
  }) async {
    try {
      await _client
          .from('kyc_verifications')
          .update({'status': status, 'rejection_reason': reason})
          .eq('id', kycId);

      final String profileStatus = status == 'verified'
          ? 'verified'
          : 'rejected';
      await _client
          .from('profiles')
          .update({'kyc_status': profileStatus})
          .eq('id', userId);

      // 3. Notify the user (Only if not already notified for this specific status)
      final existingNoteList = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('type', 'kyc_update')
          .eq(
            'title',
            status == 'verified' ? 'KYC Approved! ✅' : 'KYC Rejected ❌',
          )
          .limit(1);

      if (existingNoteList.isEmpty) {
        await _client.from('notifications').insert({
          'user_id': userId,
          'title': status == 'verified' ? 'KYC Approved! ✅' : 'KYC Rejected ❌',
          'message': status == 'verified' 
            ? 'Congratulations! Your identity verification was successful. You can now post properties.'
            : 'Your identity verification was rejected. Reason: ${reason ?? "No reason provided"}. Please re-submit.',
          'type': 'kyc_update',
        });
      }
    } catch (e) {
      print('Error updating KYC status: $e');
      rethrow;
    }
  }

  /// Fetch all properties for moderation
  static Future<List<Map<String, dynamic>>> getAllPropertiesForAdmin() async {
    try {
      return await _client
          .from('properties')
          .select('*, property_images(*), profiles(full_name)')
          .order('created_at', ascending: false);
    } catch (e) {
      print('Error fetching properties for admin: $e');
      return [];
    }
  }

  /// Update property status
  static Future<void> updatePropertyStatus(String id, String status) async {
    try {
      await _client.from('properties').update({'status': status}).eq('id', id);
    } catch (e) {
      print('Error updating property status: $e');
      rethrow;
    }
  }

  /// Delete property permanently
  static Future<void> deletePropertyPermanently(String id) async {
    try {
      // images are linked via cascade in DB, but we delete explicitly for safety
      await _client.from('property_images').delete().eq('property_id', id);
      await _client.from('properties').delete().eq('id', id);
    } catch (e) {
      print('Error deleting property permanently: $e');
      rethrow;
    }
  }

  /// Delete a KYC record permanently
  static Future<void> deleteKycPermanently(String kycId) async {
    try {
      await _client.from('kyc_verifications').delete().eq('id', kycId);
    } catch (e) {
      print('Error deleting KYC: $e');
      rethrow;
    }
  }

  /// Delete a user profile permanently
  static Future<void> deleteUserPermanently(String userId) async {
    try {
      // cascading will hopefully handle these, but we can be explicit
      await _client.from('kyc_verifications').delete().eq('user_id', userId);
      await _client.from('notifications').delete().eq('user_id', userId);
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Fetch all users for management
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      return await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
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

  /// NEW: Robust initializer for all real-time listeners
  static void initRealtimeListeners({Function? onOwnerEvent}) {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // 1. Clean up existing channels to prevent duplicates
    _notificationChannel?.unsubscribe();
    _ownerKycChannel?.unsubscribe();
    _ownerReportChannel?.unsubscribe();

    // 2. User Notifications Channel
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
            
            // Push to global notifier if it's a KYC update
            final data = payload.newRecord;
            if (data['type'] == 'kyc_update' || 
               (data['title'] ?? '').toString().contains('KYC')) {
              lastKycNotification.value = data;
            }
          },
        );
    _notificationChannel?.subscribe();
    // 3. User Messages Channel (for badges)
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
            // New message received!
            fetchUnreadMessageCount();
          },
        )
        .subscribe();

    // Fetch initial unread counts
    fetchUnreadNotificationCount();
    fetchUnreadMessageCount();
  }

  /// DEPRECATED: Use initRealtimeListeners
  static void listenToUserNotifications() {}

  /// Save the user's FCM Push Token (Digital Mailing Address)
  static Future<void> saveDeviceToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Save it to 'fcm_token' column in profiles table
      await _client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      print('Error saving FCM Token: $e');
    }
  }

  /// OWNER ONLY: Listen for new KYC submissions and reports across the whole platform
  static void listenToOwnerAlerts(Function onNewEvent) {
    final user = _client.auth.currentUser;
    // Only proceed if the logged in user is the specific admin email
    if (user == null || user.email != 'khoznaapp@gmail.com') return;

    // Listen for new KYC submissions
    _client
        .channel('owner-kycs')
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

    // Listen for new User Reports
    _client
        .channel('owner-reports')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_reports',
          callback: (payload) {
            // New report submitted!
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
      // 1. Fetch standard notifications
      final response = await _client
          .from('notifications')
          .select('*, sender:sender_id(full_name, avatar_url)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> allNotes = List<Map<String, dynamic>>.from(response);

      return allNotes;
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
          .select(
            '*, properties(*, property_images(*), profiles(full_name, avatar_url, is_verified))',
          )
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

  /// Delete all notifications for current user
  static Future<void> deleteAllNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('notifications').delete().eq('user_id', user.id);
      notificationBadgeCount.value = 0;
    } catch (e) {
      print('Error clearing notifications: $e');
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
      print('Error marking notifications as read: $e');
    }
  }

  /// Fetch the number of unread notifications
  static Future<void> fetchUnreadNotificationCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      // 1. Fetch standard unread count
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false)
          .count(CountOption.exact);
      
      int total = response.count;

      notificationBadgeCount.value = total;
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  // ==========================================
  // USER REPORTING METHODS
  // ==========================================

  /// Report a user for bad behavior
  static Future<void> reportUser(
    String userId,
    String reporterId,
    String reason,
  ) async {
    try {
      await _client.from('user_reports').insert({
        'reported_user_id': userId,
        'reporter_id': reporterId,
        'reason': reason,
      });
    } catch (e) {
      print('Error reporting user: $e');
      rethrow;
    }
  }

  /// Fetch all user reports for admin
  static Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      return await _client
          .from('user_reports')
          .select(
            '*, reported:reported_user_id(full_name, avatar_url), reporter:reporter_id(full_name)',
          )
          .order('created_at', ascending: false);
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  /// Delete a report record
  static Future<void> deleteReport(String reportId) async {
    try {
      await _client.from('user_reports').delete().eq('id', reportId);
    } catch (e) {
      print('Error deleting report: $e');
      rethrow;
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
      // 1. Fetch chats where user is a participant
      final response = await _client
          .from('chats')
          .select()
          .contains('participants', [user.id])
          .order('last_message_time', ascending: false);

      List<Map<String, dynamic>> chats = List<Map<String, dynamic>>.from(response);

      // 2. Enrich with other participant's profile and unread counts
      for (var chat in chats) {
        final List participants = chat['participants'] ?? [];
        final String? otherUserId = participants.firstWhere(
          (id) => id != user.id,
          orElse: () => null,
        );

        if (otherUserId != null) {
          chat['sender'] = await getUserProfile(otherUserId);
        }

        final unreadResponse = await _client
            .from('messages')
            .select()
            .eq('chat_id', chat['id'])
            .eq('is_read', false)
            .neq('sender_id', user.id)
            .count(CountOption.exact);
        chat['unread_count'] = unreadResponse.count;
      }

      return chats;
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  /// Get or create a chat thread with another user
  static Future<String> getOrCreateChat(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 1. Check if chat already exists
      final existing = await _client.from('chats').select().contains(
        'participants',
        [user.id, otherUserId],
      ).maybeSingle();

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
        .order('created_at', ascending: false)
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
        'is_read': false,
      });

      // Update the chat's updated_at timestamp for sorting
      // (Trigger handles last_message_text in DB)
      await _client
          .from('chats')
          .update({
            'updated_at': DateTime.now().toIso8601String(),
            'deleted_for': [], // Clear deleted state so the chat reappears
          })
          .eq('id', chatId);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Mark all messages in a chat as read
  static Future<void> markChatAsRead(String chatId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .eq('is_read', false)
          .neq('sender_id', user.id);
      
      // Update global count
      fetchUnreadMessageCount();
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  /// Fetch total unread message count across all chats
  static Future<void> fetchUnreadMessageCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Get IDs of all chats the user is in
      final chatsResponse = await _client
          .from('chats')
          .select('id')
          .contains('participants', [user.id]);
      
      final chatIds = (chatsResponse as List).map((c) => c['id']).toList();
      
      if (chatIds.isEmpty) {
        messageBadgeCount.value = 0;
        return;
      }

      // 2. Count unread messages ONLY in those chats
      final response = await _client
          .from('messages')
          .select()
          .inFilter('chat_id', chatIds)
          .eq('is_read', false)
          .neq('sender_id', user.id)
          .count(CountOption.exact);
      
      messageBadgeCount.value = response.count;
    } catch (e) {
      debugPrint('Error fetching unread message count: $e');
    }
  }

  /// Get a single booking by ID
  static Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .maybeSingle();
    return response;
  }

  /// Get all bookings where the current user is the guest
  static Future<List<Map<String, dynamic>>> getMyBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    
    final response = await _client
        .from('bookings')
        .select()
        .eq('guest_id', user.id)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Mark all messages across all chats as read for the current user
  static Future<void> markAllMessagesAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.rpc('mark_all_messages_as_read', params: {
        'target_user_id': user.id,
      });
      
      // Update global count
      messageBadgeCount.value = 0;
    } catch (e) {
      print('Error marking all messages as read: $e');
    }
  }

  /// Get all booking requests for properties owned by the current user
  static Future<List<Map<String, dynamic>>> getBookingRequestsForOwner() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    
    final response = await _client
        .from('bookings')
        .select()
        .eq('owner_id', user.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // ==========================================
  // DELETE & MEDIA METHODS
  // ==========================================

  /// Delete a single message (only the sender can delete their own message)
  static Future<void> deleteMessage(String messageId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', user.id);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Permanently delete entire chat for the current user only (soft-delete via deleted_for array)
  static Future<void> deleteChat(String chatId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      // Fetch existing deleted_for array
      final chat = await _client
          .from('chats')
          .select('deleted_for')
          .eq('id', chatId)
          .maybeSingle();

      final List<dynamic> existing =
          List<dynamic>.from(chat?['deleted_for'] ?? []);
      if (!existing.contains(user.id)) {
        existing.add(user.id);
      }

      await _client
          .from('chats')
          .update({'deleted_for': existing})
          .eq('id', chatId);
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  /// Send an image message — stores image_url in messages table
  static Future<void> sendImageMessage(String chatId, String imageUrl) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': user.id,
        'text': null,
        'image_url': imageUrl,
        'is_read': false,
      });

      await _client
          .from('chats')
          .update({
            'updated_at': DateTime.now().toIso8601String(),
            'last_message_text': '📷 Photo',
          })
          .eq('id', chatId);
    } catch (e) {
      debugPrint('Error sending image message: $e');
      rethrow;
    }
  }
}

