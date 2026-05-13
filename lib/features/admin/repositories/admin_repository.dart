import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/models/admin_model.dart';
import 'package:khozna/core/models/booking_model.dart';

class AdminRepository {
  static final _client = Supabase.instance.client;

  static Future<AdminStatsModel> getStats() async {
    final users = await _client.from('profiles').select('id');
    final properties = await _client.from('properties').select('id');
    final kyc = await _client.from('kyc_verifications').select('id').eq('status', 'pending');
    final reports = await _client.from('user_reports').select('id').eq('status', 'pending');
    final bookings = await _client.from('bookings').select('id').eq('status', 'confirmed');

    return AdminStatsModel(
      totalUsers: (users as List).length,
      totalProperties: (properties as List).length,
      pendingKyc: (kyc as List).length,
      pendingReports: (reports as List).length,
      activeBookings: (bookings as List).length,
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingPayments() async {
    final response = await _client
        .from('payments')
        .select('*, bookings(*, properties(title), guest:payer_id(full_name), owner:owner_id(full_name, esewa_number, khalti_number, qr_code_url))')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> verifyPayment(String paymentId, String bookingId, bool approved) async {
    final status = approved ? 'verified' : 'rejected';
    final bookingStatus = approved ? 'paid' : 'awaiting_payment';

    await _client.from('payments').update({'status': status}).eq('id', paymentId);
    await _client.from('bookings').update({'status': bookingStatus}).eq('id', bookingId);
  }
}
