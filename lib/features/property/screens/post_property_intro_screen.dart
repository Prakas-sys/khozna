import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/screens/add_property_screen.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';

class PostPropertyIntroScreen extends StatefulWidget {
  const PostPropertyIntroScreen({super.key});

  @override
  State<PostPropertyIntroScreen> createState() => _PostPropertyIntroScreenState();
}

class _PostPropertyIntroScreenState extends State<PostPropertyIntroScreen> {
  int _listingCount = 0;
  bool _isKycVerified = false;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch listing count
      final countRes = await Supabase.instance.client
          .from('properties')
          .select('id')
          .eq('owner_id', user.id);
      final int count = (countRes as List).length;

      // Fetch KYC status
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('kyc_status')
          .eq('id', user.id)
          .maybeSingle();
      final bool verified = profile?['kyc_status'] == 'verified';

      if (mounted) {
        setState(() {
          _listingCount = count;
          _isKycVerified = verified;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('PostPropertyIntroScreen stats error: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showWarning = !_isLoadingStats && !_isKycVerified && _listingCount > 0;
    final int remaining = 3 - _listingCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ⚠️ KYC warning banner for unverified landlords
                    if (showWarning) ...[
                      _buildKycWarningBanner(remaining),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Start Listing on Khozna',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF222222),
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildStep(
                      stepNumber: 1,
                      title: 'Property details',
                      subtitle: 'Add location and room info.',
                      imagePath: 'assets/icons/1.png',
                    ),
                    
                    _buildStep(
                      stepNumber: 2,
                      title: 'Add photos and Videos',
                      subtitle: 'Upload photos, videos and description.',
                      imagePath: 'assets/icons/2.png',
                    ),
                    
                    _buildStep(
                      stepNumber: 3,
                      title: 'Post your property',
                      subtitle: 'Set price and publish.',
                      imagePath: 'assets/icons/3.png',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA Button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFEBEBEB),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPropertyScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycWarningBanner(int remaining) {
    final bool isLastFree = remaining == 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KycScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLastFree
              ? const Color(0xFFFFF3CD)
              : const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLastFree
                ? const Color(0xFFFFC107).withOpacity(0.6)
                : const Color(0xFFFFB300).withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLastFree ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                color: const Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLastFree
                        ? 'Last free listing!'
                        : 'Free listing: $_listingCount/3 used',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLastFree
                        ? 'After this listing, KYC verification is required. Tap to verify now and list unlimited properties.'
                        : 'You have $remaining free ${remaining == 1 ? "listing" : "listings"} remaining. Verify your identity to list unlimited properties on Khozna.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF78350F),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Verify Now →',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required String imagePath,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$stepNumber',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF222222),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF717171),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Image.asset(
                imagePath,
                width: 76,
                height: 76,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      stepNumber == 1
                          ? Icons.meeting_room_outlined
                          : stepNumber == 2
                              ? Icons.add_photo_alternate_outlined
                              : Icons.publish_outlined,
                      color: AppTheme.brandColor,
                      size: 32,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            color: Color(0xFFEBEBEB),
            thickness: 1,
            height: 1,
          ),
      ],
    );
  }
}

