import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/security/app_logger.dart';

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
      AppLogger.logApiError(
        endpoint: 'syncUserWithSupabase',
        error: e.toString(),
        context: 'Syncing user profile',
      );
    }
  }

  /// Handles Google Sign-In using Supabase (Native / Token based).
  static Future<void> signInWithIdToken({
    required String idToken,
    String? accessToken,
  }) async {
    try {
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (response.user != null) {
        await syncUserWithSupabase(response.user!);
      }
      AppLogger.logAuthAttempt(
        method: 'Google SignIn Native',
        success: true,
        userId: currentUserId,
      );
    } on SocketException catch (e) {
      debugPrint('Network error in signInWithIdToken: $e');
      throw 'No internet connection. Please check your network and try again.';
    } on AuthException catch (e) {
      debugPrint('Auth error in signInWithIdToken: ${e.message}');
      throw e.message;
    } catch (e) {
      AppLogger.logAuthAttempt(
        method: 'Google SignIn Native',
        success: false,
        error: e.toString(),
      );
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        throw 'Network connection lost. Please check your internet connection.';
      }
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
      AppLogger.logAuthAttempt(
        method: 'Google SignIn Web',
        success: true,
        userId: currentUserId,
      );
    } on SocketException catch (e) {
      debugPrint('Network error in signInWithGoogle: $e');
      throw 'No internet connection. Please check your network and try again.';
    } on AuthException catch (e) {
      debugPrint('Auth error in signInWithGoogle: ${e.message}');
      throw e.message;
    } catch (e) {
      AppLogger.logAuthAttempt(
        method: 'Google SignIn Web',
        success: false,
        error: e.toString(),
      );
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        throw 'Network connection lost. Please check your internet connection.';
      }
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
    } on SocketException catch (e) {
      debugPrint('Network error in signInWithFacebook: $e');
      throw 'No internet connection. Please check your network and try again.';
    } on AuthException catch (e) {
      debugPrint('Auth error in signInWithFacebook: ${e.message}');
      throw e.message;
    } catch (e) {
      debugPrint('Supabase Facebook Sign-In Error: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        throw 'Network connection lost. Please check your internet connection.';
      }
      rethrow;
    }
  }

  /// Signs out the current user
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on SocketException catch (e) {
      debugPrint('Network error in signOut: $e');
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }
}
