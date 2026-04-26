import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color airbnbGrey = Color(0xFF717171);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.black,
            ),
            children: [
              const TextSpan(text: 'सुरक्षा केन्द्र '),
              TextSpan(
                text: '(Safety Center)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO IMAGE / ILLUSTRATION PLACEHOLDER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.gpp_maybe_outlined,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                      children: [
                        const TextSpan(text: 'ठगीबाट बच्नुहोस्\n'),
                        TextSpan(
                          text: '(Stay Safe from Scams)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Safety Rules', 'मुख्य सुरक्षा नियमहरू'),
            const SizedBox(height: 16),
            _buildSafetyTip(
              Icons.no_sim_outlined,
              'अग्रिम पैसा नपठाउनुहोस् (No Advance Payment)',
              'प्रोपर्टी आफैंले नहेरी कसैलाई पनि बैना वा एडभान्स पैसा नपठाउनुहोस्। Khozna ले कहिल्यै पनि फोनमा पैसा माग्दैन।',
              'Never pay advance or "booking" money before visiting the property in person.',
            ),
            _buildSafetyTip(
              Icons.person_search_outlined,
              'एजेन्ट वा दलाल देखि सावधान (Beware of Brokers)',
              'Khozna सिधै घरधनी र भाडामा बस्ने बीचको माध्यम हो। यदि कसैले एजेन्ट भन्दै पैसा माग्छ भने तुरुन्त रिपोर्ट गर्नुहोस्।',
              'Khozna is for direct connection. Report anyone claiming to be an agent and asking for fees.',
            ),
            _buildSafetyTip(
              Icons.verified_user_outlined,
              'भेरिफाइड प्रयोगकर्ता मात्र (Trust Verified Users)',
              'सधैं "Verified" ब्याच भएका प्रयोगकर्ताहरूसँग मात्र कुरा गर्नुहोस्। उनीहरूको विवरण Khozna ले प्रमाणित गरेको हुन्छ।',
              'Always prioritize chatting with users who have the Blue Verified Badge.',
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('What to do?', 'शंका लागेमा के गर्ने?'),
            const SizedBox(height: 16),
            Text(
              'यदि तपाईंलाई कुनै पनि प्रयोगकर्ता वा प्रोपर्टी शंकास्पद लाग्यो भने, प्रोफाइलमा गएर "Report" बटन थिच्नुहोस्। हाम्रो टिमले तुरुन्त समीक्षा गर्नेछ।',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: airbnbGrey,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.brandColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'बुझेँ (I Understand)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String english, String nepali) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: '$nepali '),
          TextSpan(
            text: '($english)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(
    IconData icon,
    String nepaliTitle,
    String nepaliDesc,
    String englishDesc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nepaliTitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nepaliDesc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  englishDesc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
