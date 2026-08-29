import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/models/review_model.dart';
import 'package:khozna/core/security/security_utils.dart';

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
      await _client.from('notifications').insert({
        'user_id': newBooking.ownerId,
        'sender_id': user?.id,
        'title': 'नयाँ बुकिङ अनुरोध (New Booking Request! 🏠)',
        'message': '$guestName ले तपाइँको कोठा सीधा बुक गर्न अनुरोध गर्नुभएको छ।',
        'type': 'booking_request',
        'property_id': newBooking.propertyId,
        'booking_id': newBooking.id,
      });

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
        'title': 'नयाँ अवलोकन अनुरोध (New Visit Request!)',
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
          'title': 'अवलोकन स्वीकृत (Visit Approved!)',
          'message':
              'तपाइँको अवलोकन अनुरोध स्वीकृत भएको छ। कोठा हेरेर मन पराएपछि मात्र भुक्तानीको प्रक्रिया हुनेछ।',
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
        await _client.from('notifications').insert({
          'user_id': booking.ownerId,
          'sender_id': user?.id,
          'title': 'अवलोकन अनुरोध रद्द गरियो (Visit Request Cancelled)',
          'message': '$name ले अवलोकन अनुरोध रद्द गर्नुभयो।',
          'type': 'visit_cancelled',
          'property_id': booking.propertyId,
          'booking_id': bookingId,
        });
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
        await _client.from('notifications').insert({
          'user_id': booking.guestId,
          'sender_id': _client.auth.currentUser?.id,
          'title': 'अवलोकन अस्वीकृत (Visit Rejected)',
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
          'title': 'अवलोकन अनुरोध याद दिलाउँदै (Visit Reminder)',
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
      // 0. Fetch booking to get ownerId and propertyId
      final booking = await getBookingById(bookingId);
      if (booking == null) throw Exception('Booking not found');

      // 1. Update booking with payment type and status
      final double fee = paymentType == 'khozna'
          ? (amount * 0.10)
          : (amount * 0.05);

      await _client
          .from('bookings')
          .update({
            'payment_type': paymentType,
            'khozna_fee': fee,
            'status': 'paid',
            'payment_proof_url': proofImageUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId)
          .catchError((_) async {
            // Fallback in case payment_proof_url column is not on bookings table
            await _client
                .from('bookings')
                .update({
                  'payment_type': paymentType,
                  'khozna_fee': fee,
                  'status': 'paid',
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                })
                .eq('id', bookingId);
          });

      // 2. Create payment record
      await _client.from('payments').insert({
        'booking_id': bookingId,
        'payer_id': user.id,
        'amount': amount,
        'payment_method': method,
        'reference_id': referenceId,
        'proof_image_url': proofImageUrl,
        'status': 'pending',
      });

      final guestName = user.userMetadata?['full_name'] ?? 'A Guest';

      // 3. Notify owner
      await _client.from('notifications').insert({
        'user_id': booking.ownerId,
        'sender_id': user.id,
        'title': 'नयाँ भुक्तानी प्राप्त (New Payment Received! 💸)',
        'message': '$guestName ले तपाइँको कोठा (${booking.propertyTitle ?? "Property"}) को लागी भुक्तानी पठाउनुभएको छ।',
        'type': 'payment_received',
        'property_id': booking.propertyId,
        'booking_id': bookingId,
      });

      // 4. Notify guest (confirmation alert)
      await _client.from('notifications').insert({
        'user_id': user.id,
        'sender_id': booking.ownerId,
        'title': 'भुक्तानी प्रमाण पेस भयो (Payment Proof Submitted! 💳)',
        'message': '${booking.propertyTitle ?? "प्रोपर्टी"} को लागि भुक्तानीको प्रमाण सफलतापूर्वक पेस भएको छ। समीक्षा भइरहेको छ।',
        'type': 'booking_alert',
        'property_id': booking.propertyId,
        'booking_id': bookingId,
      });

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

        // 4. Airbnb Logic: Auto-cancel all other pending visit/booking requests for this property
        try {
          final pendingOthers = await _client
              .from('bookings')
              .select('id, guest_id')
              .eq('property_id', propertyId)
              .neq('id', bookingId)
              .inFilter('status', ['pending_approval', 'visit_accepted', 'awaiting_payment']);

          for (var p in pendingOthers) {
            final otherBookingId = p['id'].toString();
            final otherGuestId = p['guest_id'].toString();

            await _client
                .from('bookings')
                .update({
                  'status': 'cancelled',
                  'rejection_reason': 'Property booked by another guest',
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                })
                .eq('id', otherBookingId);

            await _client.from('notifications').insert({
              'user_id': otherGuestId,
              'sender_id': _client.auth.currentUser?.id,
              'title': 'प्रोपर्टी बुक भयो (Property Booked)',
              'message': 'यो कोठा अर्को ग्राहकद्वारा बुक भइसकेको छ।',
              'type': 'booking_alert',
              'property_id': propertyId,
              'booking_id': otherBookingId,
            });
          }
        } catch (e) {
          debugPrint('Error auto-cancelling other pending bookings: $e');
        }
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
