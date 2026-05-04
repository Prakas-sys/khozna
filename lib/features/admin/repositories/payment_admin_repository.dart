import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentAdminRepository {
  static final _client = Supabase.instance.client;

  /// Fetch all pending payments with joined guest and property info
  static Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final response = await _client
          .from('payments')
          .select('*, bookings(id, total_price, status, properties(title), profiles!bookings_guest_id_fkey(full_name, rating))')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching pending payments: $e');
      return [];
    }
  }

  /// Verify a payment
  static Future<void> verifyPayment({
    required String paymentId,
    required String bookingId,
    required String guestId,
    required String ownerId,
    required String propertyTitle,
  }) async {
    try {
      // 1. Update payment status
      await _client.from('payments').update({'status': 'verified'}).eq('id', paymentId);

      // 2. Update booking status to confirmed
      await _client.from('bookings').update({'status': 'confirmed', 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', bookingId);

      // 3. Notify Guest
      await _client.from('notifications').insert({
        'user_id': guestId,
        'title': '✅ भुक्तानी प्रमाणित (Payment Verified!)',
        'message': 'तपाइँको $propertyTitle को लागि भुक्तानी प्रमाणित भएको छ। अब तपाइँको बुकिङ निश्चित भयो।',
        'type': 'booking_alert',
        'property_id': null, // Optional
      });

      // 4. Notify Owner
      await _client.from('notifications').insert({
        'user_id': ownerId,
        'title': '💰 नयाँ भुक्तानी प्राप्त (Payment Received)',
        'message': '$propertyTitle को लागि नयाँ भुक्तानी प्रमाणित भएको छ। रकम सुरक्षित छ।',
        'type': 'booking_alert',
        'property_id': null,
      });
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      rethrow;
    }
  }

  /// Reject a payment
  static Future<void> rejectPayment({
    required String paymentId,
    required String bookingId,
    required String guestId,
    required String reason,
  }) async {
    try {
      await _client.from('payments').update({'status': 'rejected'}).eq('id', paymentId);

      // Move booking back to awaiting_payment so guest can retry
      await _client.from('bookings').update({'status': 'awaiting_payment'}).eq('id', bookingId);

      // Notify Guest
      await _client.from('notifications').insert({
        'user_id': guestId,
        'title': '❌ भुक्तानी अस्वीकृत (Payment Rejected)',
        'message': 'तपाइँको भुक्तानी अस्वीकृत भएको छ। कारण: $reason। कृपया पुन: प्रयास गर्नुहोस्।',
        'type': 'booking_alert',
      });
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
      rethrow;
    }
  }

  /// Fetch dashboard metrics
  static Future<Map<String, dynamic>> getPaymentMetrics() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

      final pendingCount = await _client.from('payments').select().eq('status', 'pending').count(CountOption.exact);
      final verifiedToday = await _client.from('payments').select().eq('status', 'verified').gte('created_at', todayStart).count(CountOption.exact);
      final rejectedToday = await _client.from('payments').select().eq('status', 'rejected').gte('created_at', todayStart).count(CountOption.exact);
      
      final totalVerifiedRes = await _client.from('payments').select('amount').eq('status', 'verified');
      double totalVerifiedAmount = 0;
      for (var row in (totalVerifiedRes as List)) {
        totalVerifiedAmount += double.tryParse(row['amount']?.toString() ?? '0') ?? 0;
      }

      return {
        'pending_count': pendingCount.count,
        'verified_today': verifiedToday.count,
        'rejected_today': rejectedToday.count,
        'total_amount': totalVerifiedAmount,
      };
    } catch (e) {
      debugPrint('Error fetching metrics: $e');
      return {'pending_count': 0, 'verified_today': 0, 'rejected_today': 0, 'total_amount': 0.0};
    }
  }

  /// Fetch payment history
  static Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final response = await _client
          .from('payments')
          .select('*, bookings(properties(title), profiles!bookings_guest_id_fkey(full_name))')
          .neq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(50);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }
}
