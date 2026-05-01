import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/admin_model.dart';

class AdminRepository {
  static final _client = Supabase.instance.client;

  static Future<AdminStatsModel> getAdminStats() async {
    try {
      final userCount = await _client.from('profiles').select().count(CountOption.exact);
      final propertyCount = await _client.from('properties').select().count(CountOption.exact);
      final pendingKycCount = await _client.from('kyc_verifications').select().eq('status', 'pending').count(CountOption.exact);
      final reportCount = await _client.from('user_reports').select().count(CountOption.exact);
      final bookingCount = await _client.from('properties').select().eq('status', 'booked').count(CountOption.exact);

      return AdminStatsModel(
        totalUsers: userCount.count,
        totalProperties: propertyCount.count,
        pendingKyc: pendingKycCount.count,
        pendingReports: reportCount.count,
        activeBookings: bookingCount.count,
      );
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
      return AdminStatsModel(totalUsers: 0, totalProperties: 0, pendingKyc: 0, pendingReports: 0, activeBookings: 0);
    }
  }

  static Future<List<KycVerificationModel>> getPendingKycs() async {
    try {
      final response = await _client.from('kyc_verifications').select().eq('status', 'pending').order('created_at');
      return (response as List).map((e) => KycVerificationModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching pending KYCs: $e');
      return [];
    }
  }

  static Future<KycVerificationModel?> getKycByUserId(String userId) async {
    try {
      final response = await _client.from('kyc_verifications').select().eq('user_id', userId).order('created_at', ascending: false).limit(1).maybeSingle();
      if (response == null) return null;
      return KycVerificationModel.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching KYC for $userId: $e');
      return null;
    }
  }

  static Future<void> updateKycStatus(String kycId, String userId, String status, {String? reason}) async {
    await _client.from('kyc_verifications').update({'status': status, 'rejection_reason': reason}).eq('id', kycId);
    final String profileStatus = status == 'verified' ? 'verified' : 'rejected';
    await _client.from('profiles').update({'kyc_status': profileStatus}).eq('id', userId);

    // Only create notification if it doesn't exist for this specific status change
    final existing = await _client.from('notifications').select().eq('user_id', userId).eq('type', 'kyc_update').eq('title', status == 'verified' ? 'KYC Approved! ✅' : 'KYC Rejected ❌').limit(1);
    
    if (existing.isEmpty) {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': status == 'verified' ? 'KYC Approved! ✅' : 'KYC Rejected ❌',
        'message': status == 'verified' ? 'Congratulations! Your identity verification was successful.' : 'Your identity verification was rejected. Reason: ${reason ?? "No reason provided"}.',
        'type': 'kyc_update',
      });
    }
  }

  static Future<void> deleteKycPermanently(String kycId) async {
    await _client.from('kyc_verifications').delete().eq('id', kycId);
  }

  static void listenToAdminAlerts(Function onNewEvent) {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    // We fetch the profile to check the is_admin flag we added
    _client.from('profiles').select('is_admin').eq('id', user.id).single().then((profile) {
      if (profile['is_admin'] != true) return;
      
      _client.channel('admin-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert, 
          schema: 'public', 
          table: 'kyc_verifications', 
          callback: (_) { 
            notificationBadgeCount.value++; 
            onNewEvent(); 
          }
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert, 
          schema: 'public', 
          table: 'user_reports', 
          callback: (_) { 
            notificationBadgeCount.value++; 
            onNewEvent(); 
          }
        )
        .subscribe();
    });
  }
}
