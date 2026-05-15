import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';

/// Checks if the current user has completed KYC.
/// If not, shows a premium bottom sheet prompting them to verify.
/// Returns [true] if the user is verified and can proceed, [false] otherwise.
class KycGuard {
  static Future<bool> check(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('kyc_status')
          .eq('id', user.id)
          .maybeSingle();

      final status = profile?['kyc_status'] ?? 'not_started';
      if (status == 'verified') return true;

      // Not verified — show gate sheet
      if (context.mounted) {
        await _showKycGateSheet(context, status);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showKycGateSheet(
    BuildContext context,
    String status,
  ) async {
    final bool isPending = status == 'pending';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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

            // Shield icon with brand glow
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
                Icons.verified_user_rounded,
                color: AppTheme.brandColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isPending ? 'VERIFICATION IN PROGRESS' : 'VERIFY YOUR IDENTITY',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isPending
                  ? 'तपाईंको KYC कागजातहरू समीक्षा भइरहेका छन्। यसलाई सामान्यतया २४–४८ घण्टा लाग्छ। स्वीकृत भएपछि तपाईंले घरधनीहरूलाई सन्देश पठाउन सक्नुहुनेछ।'
                  : 'घरधनीहरूलाई सन्देश पठाउन र अवलोकन तालिका बनाउन, तपाईंले आफ्नो पहिचान प्रमाणित गर्न आवश्यक छ। यसले घरधनीहरूलाई तपाईं एक वास्तविक भाडामा बस्ने व्यक्तिको रूपमा विश्वास गर्न मद्दत गर्दछ।',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Trust points
            _buildTrustPoint(
              Icons.security_rounded,
              'Builds trust with property owners',
            ),
            _buildTrustPoint(
              Icons.speed_rounded,
              'Faster responses from owners',
            ),
            _buildTrustPoint(
              Icons.lock_rounded,
              'Your data is safe & encrypted',
            ),
            const SizedBox(height: 28),

            if (!isPending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KycScreen()),
                    );
                  },
                  icon: const Icon(Icons.verified_user_rounded, size: 18),
                  label: Text(
                    'Verify My Identity (KYC)',
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
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Review Pending — Please Wait',
                      style: GoogleFonts.inter(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.inter(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTrustPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.brandColor, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
