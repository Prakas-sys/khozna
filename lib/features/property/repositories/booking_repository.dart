import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/models/review_model.dart';
import 'package:khozna/core/security/security_utils.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/services/push_notification_service.dart';

class BookingRepository {
  static final _client = Supabase.instance.client;

  static final Map<String, String> propertyBookingStatusCache = {};
  static final Map<String, String> propertyBookingIdCache = {};


  /// Initial Load: Fetch all IDs the user has booked/pending.
  static Future<void> fetchBookedPropertyIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('bookings')
          .select('id, property_id, status')
          .eq('guest_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );

      final Set<String> activeBooked = {};
      propertyBookingStatusCache.clear();
      propertyBookingIdCache.clear();

      for (final row in data) {
        final propId = row['property_id']?.toString();
        final status = row['status']?.toString();
        final bId = row['id']?.toString();

        if (propId != null && status != null && bId != null) {
          if (!propertyBookingStatusCache.containsKey(propId)) {
            propertyBookingStatusCache[propId] = status;
            propertyBookingIdCache[propId] = bId;
          }

          if (['pending_approval', 'visit_accepted', 'awaiting_payment', 'paid', 'confirmed'].contains(status)) {
            activeBooked.add(propId);
          }
        }
      }

      bookedPropertiesStore.value = activeBooked;
    } catch (e) {
      debugPrint('Error fetching booked IDs: $e');
    }
  }

  /// Fetch all dates that are already taken for a property.
  /// Returns a Set of date strings in 'yyyy-MM-dd' format.
  static Future<Set<String>> fetchUnavailableDates(String propertyId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('check_in')
          .eq('property_id', propertyId)
          .inFilter('status', [
            'pending_approval',
            'visit_accepted',
            'awaiting_payment',
            'paid',
            'confirmed',
          ]);

      final Set<String> blocked = {};
      for (final row in List<Map<String, dynamic>>.from(response)) {
        final raw = row['check_in']?.toString();
        if (raw != null) {
          final dt = DateTime.tryParse(raw);
          if (dt != null) {
            // Block the whole calendar day
            blocked.add('${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}');
          }
        }
      }
      return blocked;
    } catch (e) {
      debugPrint('fetchUnavailableDates error: $e');
      return {};
    }
  }

  static Future<BookingModel?> createBooking(BookingModel booking) async {
    try {
      final user = _client.auth.currentUser;
      final response = await _client
          .from('bookings')
          .insert(booking.toMap())
          .select()
          .single();
      
      final newBooking = BookingModel.fromMap(response);

      // Notify owner about the NEW BOOKING REQUEST
      final String guestName = user?.userMetadata?['full_name'] ?? 'A Guest';
      final String bTitle = 'नयाँ बुकिङ अनुरोध (New Booking Request! 🏠)';
      final String bMessage = '$guestName ले तपाइँको कोठा सीधा बुक गर्न अनुरोध गर्नुभएको छ।';

      await _client.from('notifications').insert({
        'user_id': newBooking.ownerId,
        'sender_id': user?.id,
        'title': bTitle,
        'message': bMessage,
        'type': 'booking_request',
        'property_id': newBooking.propertyId,
        'booking_id': newBooking.id,
      });

      PushNotificationService.sendPushToUserId(
        recipientUserId: newBooking.ownerId,
        title: bTitle,
        body: bMessage,
        data: {'type': 'booking_request', 'booking_id': newBooking.id},
      );

      return newBooking;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
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
      // Option A: Prevent duplicate pending/accepted visit requests for the same property
      final existing = await _client
          .from('bookings')
          .select('id, status')
          .eq('property_id', propertyId)
          .eq('guest_id', user.id)
          .inFilter('status', ['pending_approval', 'visit_accepted', 'confirmed'])
          .maybeSingle();

      if (existing != null) {
        throw Exception('तपाइँले यस कोठाको लागि अघि नै अवलोकन अनुरोध पठाइसक्नुभएको छ। (You already have an active request for this property.)');
      }

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
      final String vTitle = 'नयाँ अवलोकन तथा बुकिङ अनुरोध (New Booking Request!)';
      final String vMessage = '$name ले तपाइँको कोठा बुक गर्ने अनुरोध गर्नुभएको छ। ${message ?? ""}';

      await _client.from('notifications').insert({
        'user_id': ownerId,
        'sender_id': user.id,
        'title': vTitle,
        'message': vMessage,
        'type': 'visit_request',
        'property_id': propertyId,
        'booking_id': bookingId,
      });

      PushNotificationService.sendPushToUserId(
        recipientUserId: ownerId,
        title: vTitle,
        body: vMessage,
        data: {'type': 'visit_request', 'booking_id': bookingId},
      );

      return bookingId;
    } catch (e) {
      debugPrint('Booking Request Error: $e');
      rethrow;
    }
  }


  /// 2. Owner approves request -> moves to Accepted & Payment Pending
  static Future<void> approveRequest(String bookingId, {DateTime? newCheckIn}) async {
    try {
      final updates = <String, dynamic>{
        'status': 'awaiting_payment',
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
        const String title = 'बुकिङ अनुरोध स्वीकृत (Booking Request Accepted!)';
        const String body = 'तपाइँको बुकिङ अनुरोध स्वीकृत भएको छ। कृपया घरधनीलाई सिधै भुक्तानी गर्नुहोस्।';
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': title,
          'message': body,
          'type': 'visit_alert',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: booking.guestId,
          title: title,
          body: body,
          data: {'type': 'visit_alert', 'booking_id': bookingId},
        );
      } else {
        debugPrint('Could not find booking $bookingId to notify guest');
      }
    } catch (e) {
      debugPrint('Approve request error: $e');
      rethrow;
    }
  }

  /// Owner suggests a new visit time
  static Future<void> suggestNewTime(
    String bookingId, {
    required DateTime newVisitTime,
    String? message,
  }) async {
    try {
      await _client
          .from('bookings')
          .update({
            'status': 'suggested_time',
            'check_in': newVisitTime.toIso8601String(),
            'rejection_reason': message,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      final booking = await getBookingById(bookingId);
      if (booking != null) {
        final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(newVisitTime);
        const String title = 'New Visit Time Suggested ⏰';
        final String body = 'Host suggested a new visit time ($dateStr). ${message ?? ""}';
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': title,
          'message': body,
          'type': 'visit_alert',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: booking.guestId,
          title: title,
          body: body,
          data: {'type': 'visit_alert', 'booking_id': bookingId},
        );
      }
    } catch (e) {
      debugPrint('Suggest new time error: $e');
      rethrow;
    }
  }

  /// Guest accepts the new time suggested by the host
  static Future<void> guestAcceptNewTime(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({
            'status': 'visit_accepted',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      final booking = await getBookingById(bookingId);
      if (booking != null && booking.ownerId.isNotEmpty) {
        const String title = 'Visit Time Accepted ✓';
        const String body = 'Guest accepted your suggested visit time. The visit is now confirmed!';
        await _client.from('notifications').insert({
          'user_id': booking.ownerId,
          'sender_id': _client.auth.currentUser?.id,
          'title': title,
          'message': body,
          'type': 'booking_request',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: booking.ownerId,
          title: title,
          body: body,
          data: {'type': 'booking_request', 'booking_id': bookingId},
        );
      }
    } catch (e) {
      debugPrint('Guest accept new time error: $e');
      rethrow;
    }
  }

  /// Guest proposes a different visit time back to the owner
  static Future<void> guestSuggestAnotherTime(
    String bookingId, {
    required DateTime newVisitTime,
    String? message,
  }) async {
    try {
      await _client
          .from('bookings')
          .update({
            'status': 'pending_approval',
            'check_in': newVisitTime.toIso8601String(),
            'message': message,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      final booking = await getBookingById(bookingId);
      if (booking != null && booking.ownerId.isNotEmpty) {
        final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(newVisitTime);
        const String title = 'New Visit Time Requested ⏰';
        final String body = 'Guest requested a different visit time ($dateStr). ${message ?? ""}';
        await _client.from('notifications').insert({
          'user_id': booking.ownerId,
          'sender_id': _client.auth.currentUser?.id,
          'title': title,
          'message': body,
          'type': 'booking_request',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: booking.ownerId,
          title: title,
          body: body,
          data: {'type': 'booking_request', 'booking_id': bookingId},
        );
      }
    } catch (e) {
      debugPrint('Guest suggest another time error: $e');
      rethrow;
    }
  }

  static Future<void> cancelBookingRequestByGuest(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({
            'status': 'cancelled',
            'rejection_reason': 'Cancelled by guest',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      final booking = await getBookingById(bookingId);
      if (booking != null) {
        final user = _client.auth.currentUser;
        final String name = user?.userMetadata?['full_name'] ?? 'Guest';
        const String title = 'अवलोकन अनुरोध रद्द गरियो (Visit Request Cancelled)';
        final String body = '$name ले अवलोकन अनुरोध रद्द गर्नुभयो।';
        await _client.from('notifications').insert({
          'user_id': booking.ownerId,
          'sender_id': user?.id,
          'title': title,
          'message': body,
          'type': 'visit_cancelled',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: booking.ownerId,
          title: title,
          body: body,
          data: {'type': 'visit_cancelled', 'booking_id': bookingId},
        );
      }
    } catch (e) {
      debugPrint('Cancel booking request error: $e');
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
        final String displayReason = reason != null ? 'कारण: $reason' : 'घरधनीले यो समयमा अवलोकन व्यवस्था गर्न सक्नुभएन।';
        const String title = 'अवलोकन अस्वीकृत (Visit Rejected)';
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': title,
          'message': displayReason,
          'type': 'visit_alert',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: booking.guestId,
          title: title,
          body: displayReason,
          data: {'type': 'visit_alert', 'booking_id': bookingId},
        );
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
        const String title = 'अवलोकन अनुरोध याद दिलाउँदै (Visit Reminder)';
        final String body = '$name ले तपाइँको जवाफको लागि प्रतीक्षा गर्दैछ।';
        await _client.from('notifications').insert({
          'user_id': booking.ownerId,
          'sender_id': user?.id,
          'title': title,
          'message': body,
          'type': 'visit_reminder',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: booking.ownerId,
          title: title,
          body: body,
          data: {'type': 'visit_reminder', 'booking_id': bookingId},
        );
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

  /// 3. Guest submits payment directly to property owner
  static Future<void> submitPayment({
    required String bookingId,
    String paymentType = 'direct',
    required String method, // 'esewa', 'khalti', 'bank_transfer', 'qr'
    required double amount,
    String? referenceId,
    String? proofImageUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // 0. Fetch booking to get ownerId and propertyId
      final booking = await getBookingById(bookingId);
      if (booking == null) throw Exception('Booking not found');

      // 1. Update booking with direct payment status
      final updates = <String, dynamic>{
        'payment_type': 'direct',
        'khozna_fee': 0.0,
        'status': 'paid',
        'payment_proof_url': proofImageUrl,
        'payment_reference': referenceId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        await _client
            .from('bookings')
            .update(updates)
            .eq('id', bookingId);
      } catch (_) {
        // Fallback if some schema columns are missing
        await _client
            .from('bookings')
            .update({
              'payment_type': 'direct',
              'status': 'paid',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', bookingId);
      }

      // 2. Create payment record
      try {
        await _client.from('payments').insert({
          'booking_id': bookingId,
          'payer_id': user.id,
          'amount': amount,
          'payment_method': method,
          'reference_id': referenceId,
          'proof_image_url': proofImageUrl,
          'status': 'submitted',
        });
      } catch (e) {
        debugPrint('Payment record creation notice: $e');
      }

      final guestName = user.userMetadata?['full_name'] ?? 'A Guest';

      // 3. Notify owner
      const String pTitle = 'भुक्तानी विवरण प्राप्त भयो (Payment Info Submitted 💸)';
      final String refInfo = referenceId != null && referenceId.isNotEmpty ? ' (Ref: $referenceId)' : '';
      final String pBody = '$guestName ले घरधनीको खातामा सिधै भुक्तानी पठाउनुभएको छ$refInfo। कृपया विवरण जाँच गरी स्वीकृत गर्नुहोस्।';
      await _client.from('notifications').insert({
        'user_id': booking.ownerId,
        'sender_id': user.id,
        'title': pTitle,
        'message': pBody,
        'type': 'payment_received',
        'property_id': booking.propertyId,
        'booking_id': bookingId,
      });

      PushNotificationService.sendPushToUserId(
        recipientUserId: booking.ownerId,
        title: pTitle,
        body: pBody,
        data: {'type': 'payment_received', 'booking_id': bookingId},
      );

    } catch (e) {
      debugPrint('Submit payment error: $e');
      rethrow;
    }
  }

  /// Owner confirms payment receipt -> moves booking to Confirmed
  static Future<void> confirmPayment(String bookingId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, properties(id, category, price_month, price_night)')
          .eq('id', bookingId)
          .single();

      final String guestId = response['guest_id']?.toString() ?? '';

      // Update booking and payment status
      await _client
          .from('bookings')
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      try {
        await _client
            .from('payments')
            .update({'status': 'verified'})
            .eq('booking_id', bookingId);
      } catch (_) {}

      // Notify confirmed guest
      if (guestId.isNotEmpty) {
        const String confTitle = 'बुकिङ पक्का भयो! (Booking Confirmed! 🏠)';
        const String confBody = 'घरधनीले भुक्तानी प्राप्त भएको पुष्टि गर्नुभयो। तपाइँको बुकिङ पक्का भएको छ!';
        await _client.from('notifications').insert({
          'user_id': guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': confTitle,
          'message': confBody,
          'type': 'booking_confirmed',
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: guestId,
          title: confTitle,
          body: confBody,
          data: {'type': 'booking_confirmed', 'booking_id': bookingId},
        );
      }
    } catch (e) {
      debugPrint('Confirm payment error: $e');
      rethrow;
    }
  }

  /// Owner reports a payment issue or invalid transaction reference
  static Future<void> rejectPayment(String bookingId, {String? reason}) async {
    try {
      await _client
          .from('bookings')
          .update({
            'status': 'payment_issue',
            'rejection_reason': reason ?? 'Payment verification failed',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      final booking = await getBookingById(bookingId);
      if (booking != null && booking.guestId.isNotEmpty) {
        const String title = 'भुक्तानी प्रमाणीकरण हुन सकेन (Payment Issue ⚠️)';
        final String body = 'घरधनीले तपाइँको भुक्तानी प्रमाणीकरण गर्न सक्नुभएन। ${reason ?? "कृपया पुनः विवरण वा प्रमाण पठाउनुहोस्।"}';
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': title,
          'message': body,
          'type': 'payment_issue',
          'booking_id': bookingId,
        });

        PushNotificationService.sendPushToUserId(
          recipientUserId: booking.guestId,
          title: title,
          body: body,
          data: {'type': 'payment_issue', 'booking_id': bookingId},
        );
      }
    } catch (e) {
      debugPrint('Reject payment error: $e');
      rethrow;
    }
  }

  static Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, properties(title, price, price_month, price_night)')
          .eq('id', bookingId)
          .maybeSingle();

      if (response == null) return null;

      final Map<String, dynamic> data = Map<String, dynamic>.from(response);
      if (data['properties'] != null) {
        data['property_title'] = data['properties']['title'];

        final double pm = double.tryParse(data['properties']['price_month']?.toString() ?? '0') ?? 0;
        final double pn = double.tryParse(data['properties']['price_night']?.toString() ?? '0') ?? 0;
        final double p = double.tryParse(data['properties']['price']?.toString().replaceAll(',', '') ?? '0') ?? 0;
        final double propPrice = pm > 0 ? pm : (pn > 0 ? pn : p);

        final double currentTotal = double.tryParse(data['total_price']?.toString() ?? '0') ?? 0;
        if (currentTotal <= 0 && propPrice > 0) {
          data['total_price'] = propPrice;
        }
      }

      return BookingModel.fromMap(data);
    } catch (e) {
      debugPrint('Error getting booking $bookingId: $e');
      return null;
    }
  }

  static Future<List<BookingModel>> getMyBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('guest_id', user.id)
          .order('created_at', ascending: false);
      return (response as List).map((e) => BookingModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching my bookings: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _cachedOwnerBookings = [];
  static final Set<String> _deletedBookingIds = {};

  static List<Map<String, dynamic>> get cachedOwnerBookings {
    return _cachedOwnerBookings.where((item) => !_deletedBookingIds.contains(item['id']?.toString())).toList();
  }

  static Future<List<Map<String, dynamic>>> getOwnerBookings({bool forceRefresh = false}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Return cached result immediately if available
    if (_cachedOwnerBookings.isNotEmpty && !forceRefresh) {
      final filteredCache = _cachedOwnerBookings.where((item) => !_deletedBookingIds.contains(item['id']?.toString())).toList();
      // Refresh in background asynchronously
      _client
          .from('bookings')
          .select(
            '*, properties(title, area_name, images), guest:profiles!bookings_guest_id_fkey(full_name, avatar_url, phone_number, email), payments(id, proof_image_url, reference_id, payment_method, amount)',
          )
          .eq('owner_id', user.id)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false)
          .then((response) {
            final fresh = List<Map<String, dynamic>>.from(response)
                .where((item) => !_deletedBookingIds.contains(item['id']?.toString()))
                .toList();
            _cachedOwnerBookings = fresh;
          })
          .catchError((e) {
            debugPrint('Background fetch owner bookings error: $e');
          });
      return filteredCache;
    }

    try {
      final response = await _client
          .from('bookings')
          .select(
            '*, properties(title, area_name, images), guest:profiles!bookings_guest_id_fkey(full_name, avatar_url, phone_number, email), payments(id, proof_image_url, reference_id, payment_method, amount)',
          )
          .eq('owner_id', user.id)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      final fresh = List<Map<String, dynamic>>.from(response)
          .where((item) => !_deletedBookingIds.contains(item['id']?.toString()))
          .toList();
      _cachedOwnerBookings = fresh;
      return _cachedOwnerBookings;
    } catch (e) {
      debugPrint('Get owner bookings error: $e');
      return _cachedOwnerBookings.where((item) => !_deletedBookingIds.contains(item['id']?.toString())).toList();
    }
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

  /// Delete / Remove a visit request permanently from the database and memory
  static Future<void> deleteBookingRequest(String bookingId) async {
    // 0. Remove from local memory cache & mark as deleted in memory permanently
    _deletedBookingIds.add(bookingId);
    _cachedOwnerBookings.removeWhere((item) => item['id']?.toString() == bookingId);

    try {
      // 1. Delete notifications referencing this booking first
      try {
        await _client.from('notifications').delete().eq('booking_id', bookingId);
      } catch (e) {
        debugPrint('Notification cleanup error: $e');
      }

      // 2. Delete payments referencing this booking
      try {
        await _client.from('payments').delete().eq('booking_id', bookingId);
      } catch (e) {
        debugPrint('Payments cleanup error: $e');
      }

      // 3. Delete reviews referencing this booking
      try {
        await _client.from('reviews').delete().eq('booking_id', bookingId);
      } catch (e) {
        debugPrint('Reviews cleanup error: $e');
      }

      // 4. ALWAYS update status to 'cancelled' so Supabase UPDATE RLS policy marks it cancelled in DB
      try {
        await _client
            .from('bookings')
            .update({
              'status': 'cancelled',
              'rejection_reason': 'Deleted by user',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', bookingId);
      } catch (e) {
        debugPrint('Status update cancellation error: $e');
      }

      // 5. Try direct SQL DELETE as well
      try {
        await _client.from('bookings').delete().eq('id', bookingId);
      } catch (e) {
        debugPrint('Direct DB Delete error: $e');
      }

      // 6. Ensure memory cache stays clean
      _deletedBookingIds.add(bookingId);
      _cachedOwnerBookings.removeWhere((item) => item['id']?.toString() == bookingId);
    } catch (e) {
      debugPrint('Delete booking request error: $e');
      _deletedBookingIds.add(bookingId);
      _cachedOwnerBookings.removeWhere((item) => item['id']?.toString() == bookingId);
    }
  }
}
