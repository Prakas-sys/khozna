import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/models/review_model.dart';
import 'package:khozna/core/models/payment_model.dart';
import 'package:khozna/core/security/security_utils.dart';

class BookingRepository {
  static final _client = Supabase.instance.client;

  /// Initial Load: Fetch all IDs the user has booked/pending.
  static Future<void> fetchBookedPropertyIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('bookings')
          .select('property_id')
          .eq('guest_id', user.id)
          .inFilter('status', [
            'pending_approval',
            'awaiting_payment',
            'paid',
            'confirmed',
          ]);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );
      final set = data.map((e) => e['property_id'].toString()).toSet();
      bookedPropertiesStore.value = set;
    } catch (e) {
      debugPrint('Error fetching booked IDs: $e');
    }
  }

  /// 1. Create a formal booking request (Guest -> Owner)
  static Future<String> createBookingRequest({
    required String propertyId,
    required String ownerId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double totalPrice,
    String? message,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final cleanMessage = message != null
          ? SecurityUtils.sanitizeInput(message, maxLength: 500)
          : '';

      final response = await _client
          .from('bookings')
          .insert({
            'property_id': propertyId,
            'guest_id': user.id,
            'owner_id': ownerId,
            'check_in': checkIn.toIso8601String(),
            'check_out': checkOut.toIso8601String(),
            'total_price': totalPrice,
            'status': 'pending_approval',
          })
          .select()
          .single();

      final bookingId = response['id'];

      // Notify owner
      final String name = user.userMetadata?['full_name'] ?? 'A user';
      await _client.from('notifications').insert({
        'user_id': ownerId,
        'sender_id': user.id,
        'title': 'नयाँ भ्रमण अनुरोध (New Visit Request!)',
        'message':
            '$name ले तपाइँको कोठा हेर्न अनुरोध गर्नुभएको छ। ${message ?? ""}',
        'type': 'visit_request',
        'property_id': propertyId,
        'booking_id': bookingId,
      });

      return bookingId;
    } catch (e) {
      debugPrint('Booking Request Error: $e');
      rethrow;
    }
  }

  /// 2. Owner approves request -> moves to Visit Accepted
  static Future<void> approveRequest(String bookingId, {DateTime? newCheckIn}) async {
    try {
      final updates = <String, dynamic>{
        'status': 'visit_accepted',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      if (newCheckIn != null) {
        updates['check_in'] = newCheckIn.toIso8601String();
      }

      await _client
          .from('bookings')
          .update(updates)
          .eq('id', bookingId);

      // Fetch booking to notify guest
      final booking = await getBookingById(bookingId);
      if (booking != null) {
        debugPrint('Sending approval notification to guest: ${booking.guestId}');
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': 'भ्रमण स्वीकृत (Visit Approved!)',
          'message':
              'तपाइँको भ्रमण अनुरोध स्वीकृत भएको छ। कोठा हेरेर मन पराएपछि मात्र भुक्तानीको प्रक्रिया हुनेछ।',
          'type': 'visit_alert',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });
      } else {
        debugPrint('Could not find booking $bookingId to notify guest');
      }
    } catch (e) {
      debugPrint('Approve request error: $e');
      rethrow;
    }
  }

  static Future<void> rejectRequest(String bookingId) async {
    return rejectWithReason(bookingId, reason: null);
  }

  static Future<void> rejectWithReason(
    String bookingId, {
    String? reason,
  }) async {
    try {
      await _client
          .from('bookings')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      final booking = await getBookingById(bookingId);
      if (booking != null) {
        debugPrint('Sending rejection notification to guest: ${booking.guestId}');
        final String displayReason = reason != null ? 'कारण: $reason' : 'घरधनीले यो समयमा भ्रमण व्यवस्था गर्न सक्नुभएन।';
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': 'भ्रमण अस्वीकृत (Visit Rejected)',
          'message': displayReason,
          'type': 'visit_alert',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });
      } else {
        debugPrint('Could not find booking $bookingId to notify guest of rejection');
      }
    } catch (e) {
      debugPrint('Reject request error: $e');
      rethrow;
    }
  }

  /// Remind owner about a pending request
  static Future<void> remindOwner(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking != null) {
        final user = _client.auth.currentUser;
        final String name = user?.userMetadata?['full_name'] ?? 'Guest';
        await _client.from('notifications').insert({
          'user_id': booking.ownerId,
          'sender_id': user?.id,
          'title': 'भ्रमण अनुरोध याद दिलाउँदै (Visit Reminder)',
          'message': '$name ले तपाइँको जवाफको लागि प्रतीक्षा गर्दैछ।',
          'type': 'visit_reminder',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });
      }
    } catch (e) {
      debugPrint('Remind owner error: $e');
      rethrow;
    }
  }

  /// Guest confirms they visited (yes/no)
  static Future<void> confirmVisitDone(
    String bookingId, {
    required bool visited,
  }) async {
    try {
      await _client
          .from('bookings')
          .update({
            'visit_confirmed': visited,
            'status': visited ? 'visit_accepted' : 'visit_rejected',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('Confirm visit done error: $e');
      rethrow;
    }
  }

  /// Guest confirms they liked the room — unlocks payment
  static Future<void> confirmVisitLiked(
    String bookingId, {
    required bool liked,
    String? feedbackReason,
  }) async {
    try {
      await _client
          .from('bookings')
          .update({
            'visit_liked': liked,
            'feedback_reason': feedbackReason,
            'status': liked ? 'awaiting_payment' : 'visit_completed',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('Confirm visit liked error: $e');
      rethrow;
    }
  }

  /// 3. Guest submits payment (Direct or Khozna)
  static Future<void> submitPayment({
    required String bookingId,
    required String paymentType, // 'direct' or 'khozna'
    required String method, // 'esewa', 'khalti' etc.
    required double amount,
    String? referenceId,
    String? proofImageUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Update booking with payment type and fee
      final double fee = paymentType == 'khozna'
          ? (amount * 0.10)
          : (amount * 0.05);

      await _client
          .from('bookings')
          .update({
            'payment_type': paymentType,
            'khozna_fee': fee,
            'status': 'paid',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      // Create payment record
      await _client.from('payments').insert({
        'booking_id': bookingId,
        'payer_id': user.id,
        'amount': amount,
        'payment_method': method,
        'reference_id': referenceId,
        'proof_image_url': proofImageUrl,
        'status': 'pending',
      });

      // Notify owner/admin
      // ... logic for notification
    } catch (e) {
      debugPrint('Submit payment error: $e');
      rethrow;
    }
  }

  static Future<void> confirmPayment(String bookingId) async {
    try {
      // 1. Fetch booking with property details to know the rental type
      final response = await _client
          .from('bookings')
          .select('*, properties(id, category, price_month, price_night)')
          .eq('id', bookingId)
          .single();

      final property = response['properties'];
      final String propertyId = property['id'];
      final String category = property['category']?.toString().toLowerCase() ?? '';

      // 2. Update booking and payment status
      await _client
          .from('bookings')
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      await _client
          .from('payments')
          .update({'status': 'verified'})
          .eq('booking_id', bookingId);

      // 3. Smart Property Hiding:
      // If it's a long-term rental (Room, Flat, Apartment), hide the property.
      // If it's short-term (Homestay, GuestHouse), keep it available for other nights.
      final bool isLongTerm = category == 'room' ||
          category == 'flat' ||
          category == 'apartment' ||
          category == 'house';

      if (isLongTerm) {
        await _client
            .from('properties')
            .update({'status': 'booked'})
            .eq('id', propertyId);
        debugPrint('Long-term property $propertyId marked as BOOKED (Hidden)');
      } else {
        debugPrint('Nightly property $propertyId remains AVAILABLE for other dates');
      }

      // Trigger in DB will automatically block dates in property_availability
    } catch (e) {
      debugPrint('Confirm payment error: $e');
      rethrow;
    }
  }

  static Future<void> rejectPayment(String bookingId) async {
    try {
      // Revert booking to awaiting_payment so guest can try again
      await _client
          .from('bookings')
          .update({
            'status': 'awaiting_payment',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      await _client
          .from('payments')
          .update({'status': 'failed'})
          .eq('booking_id', bookingId);
    } catch (e) {
      debugPrint('Reject payment error: $e');
      rethrow;
    }
  }

  static Future<BookingModel?> getBookingById(String bookingId) async {
    final response = await _client
        .from('bookings')
        .select('*, properties(title)')
        .eq('id', bookingId)
        .maybeSingle();

    if (response == null) return null;

    // Add property title to the model if it exists
    final Map<String, dynamic> data = Map<String, dynamic>.from(response);
    if (data['properties'] != null) {
      data['property_title'] = data['properties']['title'];
    }

    return BookingModel.fromMap(data);
  }

  static Future<List<BookingModel>> getMyBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('bookings')
        .select()
        .eq('guest_id', user.id)
        .order('created_at', ascending: false);
    return (response as List).map((e) => BookingModel.fromMap(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getOwnerBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('bookings')
        .select(
          '*, properties(title, area_name), guest:profiles!bookings_guest_id_fkey(full_name, avatar_url), payments(id, proof_image_url, reference_id)',
        )
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Guest submits a review after visiting
  static Future<void> submitReview({
    required String bookingId,
    required String propertyId,
    required String ownerId,
    required int rating,
    String? comment,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    try {
      await _client.from('reviews').insert({
        'booking_id': bookingId,
        'property_id': propertyId,
        'reviewer_id': user.id,
        'target_id': ownerId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('Review submitted: $rating stars for property $propertyId');
    } catch (e) {
      debugPrint('Submit review error: $e');
      rethrow;
    }
  }

  /// Fetch all reviews for a property (with reviewer profiles)
  static Future<List<ReviewModel>> fetchReviewsForProperty(String propertyId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, profiles!reviews_reviewer_id_fkey(full_name, avatar_url, kyc_status)')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);

      return (response as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        if (e['profiles'] != null) {
          map['reviewer_name'] = e['profiles']['full_name'];
          map['reviewer_avatar'] = e['profiles']['avatar_url'];
          map['reviewer_kyc_status'] = e['profiles']['kyc_status'];
        }
        return ReviewModel.fromMap(map);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching property reviews: $e');
      return [];
    }
  }

  /// Fetch all reviews targeting an owner/landlord (with reviewer profiles)
  static Future<List<ReviewModel>> fetchReviewsForOwner(String ownerId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, profiles!reviews_reviewer_id_fkey(full_name, avatar_url, kyc_status)')
          .eq('target_id', ownerId)
          .order('created_at', ascending: false);

      return (response as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        if (e['profiles'] != null) {
          map['reviewer_name'] = e['profiles']['full_name'];
          map['reviewer_avatar'] = e['profiles']['avatar_url'];
          map['reviewer_kyc_status'] = e['profiles']['kyc_status'];
        }
        return ReviewModel.fromMap(map);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching owner reviews: $e');
      return [];
    }
  }
}
