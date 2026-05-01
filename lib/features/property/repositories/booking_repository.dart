import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/security/security_utils.dart';

class BookingRepository {
  static final _client = Supabase.instance.client;

  /// Initial Load for Master Memory: Fetch all IDs the user has booked/pending.
  static Future<void> fetchBookedPropertyIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('bookings')
          .select('property_id')
          .eq('guest_id', user.id)
          .inFilter('status', ['pending', 'confirmed']);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );
      final set = data.map((e) => e['property_id'].toString()).toSet();
      bookedPropertiesStore.value = set;
      debugPrint(
        '--- [DATABASE] Master Memory Loaded: ${set.length} booked houses ---',
      );
    } catch (e) {
      debugPrint('Error fetching booked IDs: $e');
    }
  }

  /// Create a formal booking request
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
      // 🔐 Sanitize inputs to prevent injection attacks
      final cleanPurpose = SecurityUtils.sanitizeInput(purpose);
      final cleanMessage = SecurityUtils.sanitizeInput(message, maxLength: 1000);

      await _client.from('bookings').insert({
        'property_id': propertyId,
        'guest_id': user.id,
        'owner_id': ownerId,
        'property_title': propertyTitle,
        'move_in_date': moveInDate.toIso8601String(),
        'duration_months': durationMonths,
        'guests_count': guestCount,
        'purpose': cleanPurpose,
        'message': cleanMessage,
        'status': 'pending',
      });

      final currentBooked = Set<String>.from(bookedPropertiesStore.value);
      currentBooked.add(propertyId);
      bookedPropertiesStore.value = currentBooked;

      await _client
          .from('properties')
          .update({'status': 'pending_approval'})
          .eq('id', propertyId);

      final String name = user.userMetadata?['full_name'] ?? 'A user';
      await _client.from('notifications').insert({
        'user_id': ownerId,
        'sender_id': user.id,
        'title': '🏠 नयाँ बुकिङ अनुरोध (New Booking Request)',
        'message': '$name ले "$propertyTitle" भाडामा लिन चाहनुहुन्छ।\nबसाइँ सर्ने मिति: ${moveInDate.day}/${moveInDate.month}',
        'type': 'booking_request',
        'property_id': propertyId,
        'requester_id': user.id,
      });

      if (message.trim().isNotEmpty) {
        try {
          final chatId = await ChatRepository.getOrCreateChat(ownerId);
          await ChatRepository.sendMessage(chatId, '🏠 Booking Request for "$propertyTitle":\n\n$message');
        } catch (chatError) {
          debugPrint('Failed to send booking chat message: $chatError');
        }
      }
    } catch (e) {
      debugPrint('Booking Request Error: $e');
      rethrow;
    }
  }

  /// Owner approves a booking request
  static Future<void> approveBooking({
    required String propertyId,
    required String propertyTitle,
    required String requesterId,
    required String ownerName,
    required String notificationId,
  }) async {
    try {
      await _client
          .from('properties')
          .update({'status': 'booked'})
          .eq('id', propertyId);

      await _client
          .from('bookings')
          .update({
            'status': 'confirmed',
            'confirmed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('property_id', propertyId)
          .eq('guest_id', requesterId)
          .eq('status', 'pending');

      await _client.from('notifications').insert({
        'user_id': requesterId,
        'sender_id': _client.auth.currentUser?.id,
        'title': '✅ बुकिङ स्वीकृत (Booking Approved!)',
        'message': '$ownerName ले "$propertyTitle" को लागि तपाईंको बुकिङ स्वीकृत गर्नुभयो। सम्पर्क गरी बसाइँ सर्ने सल्लाह गर्नुहोस्।',
        'type': 'booking_approved',
        'property_id': propertyId,
      });

      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('Approve booking error: $e');
      rethrow;
    }
  }

  /// Owner rejects a booking request
  static Future<void> rejectBooking({
    required String propertyId,
    required String propertyTitle,
    required String requesterId,
    required String notificationId,
    String? reason,
  }) async {
    try {
      await _client
          .from('properties')
          .update({'status': 'available'})
          .eq('id', propertyId);

      final cleanReason = reason != null ? SecurityUtils.sanitizeInput(reason) : 'Owner declined the request.';

      await _client
          .from('bookings')
          .update({
            'status': 'rejected',
            'reject_reason': cleanReason,
          })
          .eq('property_id', propertyId)
          .eq('guest_id', requesterId)
          .eq('status', 'pending');

      await _client.from('notifications').insert({
        'user_id': requesterId,
        'sender_id': _client.auth.currentUser?.id,
        'title': '❌ बुकिङ अस्वीकृत (Booking Not Accepted)',
        'message': '"$propertyTitle" को लागि तपाईंको बुकिङ अनुरोध स्वीकृत हुन सकेन। ${reason ?? ""}',
        'type': 'booking_rejected',
        'property_id': propertyId,
      });

      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('Reject booking error: $e');
      rethrow;
    }
  }

  /// Cancel a booking
  static Future<void> cancelBooking(String propertyId) async {
    try {
      await _client
          .from('properties')
          .update({'status': 'available'})
          .eq('id', propertyId);
    } catch (e) {
      debugPrint('Supabase Cancel Booking Error: $e');
      rethrow;
    }
  }

  /// Get a single booking by ID
  static Future<BookingModel?> getBookingById(String bookingId) async {
    final response = await _client.from('bookings').select().eq('id', bookingId).maybeSingle();
    if (response == null) return null;
    return BookingModel.fromMap(response);
  }

  /// Get all bookings for guest
  static Future<List<BookingModel>> getMyBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final response = await _client.from('bookings').select().eq('guest_id', user.id).order('created_at', ascending: false);
    return (response as List).map((e) => BookingModel.fromMap(e)).toList();
  }

  /// Get all booking requests for owner
  static Future<List<BookingModel>> getBookingRequestsForOwner() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final response = await _client.from('bookings').select().eq('owner_id', user.id).eq('status', 'pending').order('created_at', ascending: false);
    return (response as List).map((e) => BookingModel.fromMap(e)).toList();
  }
}
