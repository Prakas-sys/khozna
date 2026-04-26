import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/features/TO_BE_FIXED/login_screen.dart';
import 'package:khozna/features/TO_BE_FIXED/kyc_screen.dart';

class AuthGuard {
  static final supabase = Supabase.instance.client;

  /// Returns true if user is logged in, otherwise redirects to Login and returns false.
  static bool checkAuth(BuildContext context) {
    if (supabase.auth.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return false;
    }
    return true;
  }

  /// Returns true if user is KYC verified, otherwise redirects to KycScreen and returns false.
  /// Note: Requires the latest profile data.
  static Future<bool> checkKyc(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      checkAuth(context);
      return false;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('kyc_status')
          .eq('id', user.id)
          .maybeSingle();

      final status = profile?['kyc_status'] ?? 'not_started';

      if (status != 'verified') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC Verification Required to list properties.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KycScreen()),
        );
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('AuthGuard Error: $e');
      return false;
    }
  }
}
