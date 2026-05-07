import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/core/models/booking_model.dart';
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
          .inFilter('status', ['pending_approval', 'awaiting_payment', 'paid', 'confirmed']);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
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
      final cleanMessage = message != null ? SecurityUtils.sanitizeInput(message, maxLength: 500) : '';

      final response = await _client.from('bookings').insert({
        'property_id': propertyId,
        'guest_id': user.id,
        'owner_id': ownerId,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'total_price': totalPrice,
        'status': 'pending_approval',
      }).select().single();

      final bookingId = response['id'];

      // Notify owner
      final String name = user.userMetadata?['full_name'] ?? 'A user';
      await _client.from('notifications').insert({
        'user_id': ownerId,
        'sender_id': user.id,
        'title': '👀 नयाँ भ्रमण अनुरोध (New Visit Request!)',
        'message': '$name ले तपाइँको कोठा हेर्न अनुरोध गर्नुभएको छ। ${message ?? ""}',
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

  /// 2. Owner approves request -> moves to Awaiting Payment
  static Future<void> approveRequest(String bookingId) async {
    try {
      await _client.from('bookings').update({
        'status': 'awaiting_payment',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', bookingId);

      // Fetch booking to notify guest
      final booking = await getBookingById(bookingId);
      if (booking != null) {
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': '✅ भ्रमण स्वीकृत (Visit Approved!)',
          'message': 'तपाइँको भ्रमण अनुरोध स्वीकृत भएको छ। कोठा हेरेर मन पराएपछि मात्र भुक्तानीको प्रक्रिया हुनेछ।',
          'type': 'visit_alert',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });
      }
    } catch (e) {
      debugPrint('Approve request error: $e');
      rethrow;
    }
  }

  static Future<void> rejectRequest(String bookingId) async {
    try {
      await _client.from('bookings').update({
        'status': 'rejected',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', bookingId);

      final booking = await getBookingById(bookingId);
      if (booking != null) {
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': '❌ भ्रमण अस्वीकृत (Visit Rejected)',
          'message': 'मालिकले अहिले भ्रमणको लागि समय मिलाउन सक्नुभएन।',
          'type': 'visit_alert',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });
      }
    } catch (e) {
      debugPrint('Reject request error: $e');
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
      final double fee = paymentType == 'khozna' ? (amount * 0.10) : (amount * 0.05);

      await _client.from('bookings').update({
        'payment_type': paymentType,
        'khozna_fee': fee,
        'status': 'paid',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', bookingId);

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

  /// 4. Owner/Admin confirms payment -> moves to Confirmed
  static Future<void> confirmPayment(String bookingId) async {
    try {
      await _client.from('bookings').update({
        'status': 'confirmed',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', bookingId);

      await _client.from('payments').update({
        'status': 'verified',
      }).eq('booking_id', bookingId);
      
      // Trigger in DB will automatically block dates in property_availability
    } catch (e) {
      debugPrint('Confirm payment error: $e');
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
    final response = await _client.from('bookings').select().eq('guest_id', user.id).order('created_at', ascending: false);
    return (response as List).map((e) => BookingModel.fromMap(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getOwnerBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('bookings')
        .select('*, properties(title, area_name), guest:profiles!bookings_guest_id_fkey(full_name, avatar_url)')
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
