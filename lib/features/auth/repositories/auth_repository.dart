import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  static final _client = Supabase.instance.client;

  /// Current logged-in user's ID
  static String get currentUserId => _client.auth.currentUser?.id ?? '';

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
      debugPrint('Sync Error: $e');
    }
  }

  /// Handles Google Sign-In using Supabase (Native / Token based).
  static Future<void> signInWithIdToken({
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
      debugPrint('Supabase Native Google Sign-In Error: $e');
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
      debugPrint('Supabase Google Sign-In Error: $e');
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
      debugPrint('Supabase Facebook Sign-In Error: $e');
      rethrow;
    }
  }

  /// Signs out the current user
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      rethrow;
    }
  }
}
