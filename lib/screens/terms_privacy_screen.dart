import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Terms & Privacy',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Terms of Service', 'Last Updated: April 2024'),
            const SizedBox(height: 24),
            _buildSection(
              num: '1',
              title: 'Introduction & Acceptance',
              content:
                  'By accessing or using the Khozna platform, you agree to be bound by these Terms of Service. Khozna provides a digital environment to connect property owners with potential tenants or buyers in Nepal.',
            ),
            _buildSection(
              num: '2',
              title: 'Platform Scope (Nepalese Market)',
              content:
                  'Khozna acts strictly as a bridge and facilitator. We do not participate in, control, or take responsibility for the actual rental agreements, payments, or physical handovers between users. Any transaction made outside the app is at the user\'s own risk.',
            ),
            _buildSection(
              num: '3',
              title: 'Mandatory User Verification',
              content:
                  'It is the sole responsibility of the seeker to verify the legal status of the property and the identity of the owner. Similarly, owners must verify the identity and credentials of potential seekers before concluding any deal.',
            ),
            _buildHighlightSection(
              title: 'CRITICAL: Limitation of Liability',
              content:
                  'Khozna provides the platform "as-is". We are NOT liable for any financial losses, fraud, damage to property, or harassment arising from connections made through the app. \n\nIMPORTANT: Khozna does NOT initiate or manage police reports, legal cases, or criminal investigations on behalf of users. Users must contact local authorities and the Nepal Police independently for any disputes or criminal matters.',
            ),
            _buildSection(
              num: '4',
              title: 'Moderation & Blocking',
              content:
                  'Khozna reserves the right to monitor platform usage and block any user suspected of fraud, harassment, or providing fake listings. Blocking is our primary internal enforcement mechanism. Re-entry after a block is strictly prohibited.',
            ),
            _buildSection(
              num: '5',
              title: 'Intellectual Property',
              content:
                  'All digital assets, logos, and UI designs are the exclusive property of Khozna Private Limited. Users retain ownership of their listing photos but grant Khozna a license to display them for platform functionality.',
            ),
            const SizedBox(height: 32),
            _buildHeader('Privacy Policy', 'Your data security is our priority'),
            const SizedBox(height: 24),
            _buildSection(
              num: '6',
              title: 'Data Collection',
              content:
                  'We collect minimal data required for functionality: Your phone number (for authentication), location (to show nearby properties), and listing photos.',
            ),
            _buildSection(
              num: '7',
              title: 'Data Sharing',
              content:
                  'Your contact info is only revealed when you explicitly choose to message or call another user. We do not sell your personal data to third-party advertisers.',
            ),
            _buildSection(
              num: '8',
              title: 'Governing Law',
              content:
                  'These terms are governed by the laws of Nepal. Any disputes arising from the platform architecture shall be handled in the courts of Kathmandu.',
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                '© 2024 Khozna Private Limited\nAll Rights Reserved',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.brandColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String num,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                num,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandColor.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
