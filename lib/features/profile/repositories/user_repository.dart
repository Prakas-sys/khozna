import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/security/security_utils.dart';

class UserRepository {
  static final _client = Supabase.instance.client;

  static Future<UserModel?> getUserProfile(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final response = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (response == null) return null;
      return UserModel.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching profile $userId: $e');
      return null;
    }
  }

  static Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _client.from('profiles').select().order('created_at', ascending: false);
      return (response as List).map((e) => UserModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _client.from('profiles').select().or('full_name.ilike.%$query%,phone_number.ilike.%$query%').order('created_at', ascending: false);
      return (response as List).map((e) => UserModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  static Future<void> deleteUserPermanently(String userId) async {
    await _client.from('kyc_verifications').delete().eq('user_id', userId);
    await _client.from('notifications').delete().eq('user_id', userId);
    await _client.from('profiles').delete().eq('id', userId);
  }

  static Future<void> reportUser(String userId, String reporterId, String reason) async {
    final cleanReason = SecurityUtils.sanitizeInput(reason, maxLength: 500);
    await _client.from('user_reports').insert({
      'reported_user_id': userId,
      'reporter_id': reporterId,
      'reason': cleanReason,
    });
  }

  static Future<List<UserReportModel>> getUserReports() async {
    try {
      final response = await _client.from('user_reports').select('*, reported:reported_user_id(full_name, avatar_url), reporter:reporter_id(full_name)').order('created_at', ascending: false);
      return (response as List).map((e) => UserReportModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return [];
    }
  }

  static Future<void> deleteReport(String reportId) async {
    await _client.from('user_reports').delete().eq('id', reportId);
  }
}
