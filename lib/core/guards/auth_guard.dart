import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/auth/screens/login_screen.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';

class AuthGuard {
  static final supabase = Supabase.instance.client;

  /// Returns true if user is logged in, otherwise displays the premium login prompt and returns false.
  static bool checkAuth(BuildContext context, {String? title, String? message}) {
    if (supabase.auth.currentUser == null) {
      showLoginPrompt(
        context,
        title: title ?? 'Login Required',
        message: message ?? 'Please log in to continue using this feature.',
      );
      return false;
    }
    return true;
  }

  /// Displays a gorgeous bottom sheet asking guest users to log in.
  static void showLoginPrompt(BuildContext context, {required String title, required String message}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Lock Icon with premium glowing border
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.brandColor.withOpacity(0.15),
                    AppTheme.brandColor.withOpacity(0.04),
                  ],
                ),
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: AppTheme.brandColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              title.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Dismiss bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  'Login or Register',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      // 1. Fetch current listings count
      final countRes = await supabase
          .from('properties')
          .select('id')
          .eq('owner_id', user.id);
      final int listingCount = (countRes as List).length;

      // 2. If user has less than 3 listings, let them bypass KYC!
      if (listingCount < 3) {
        return true;
      }

      // 3. Otherwise, check KYC status
      final profile = await supabase
          .from('profiles')
          .select('kyc_status')
          .eq('id', user.id)
          .maybeSingle();

      final status = profile?['kyc_status'] ?? 'not_started';

      if (status != 'verified') {
        if (status == 'pending') {
          _showPendingKycDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('KYC Verification Required to list more than 3 properties.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KycScreen()),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('AuthGuard Error: $e');
      return false;
    }
  }

  static void _showPendingKycDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_top_rounded,
                color: Colors.orange.shade700,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Verification in Progress',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your documents are being reviewed.\nVerification takes up to 48 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
