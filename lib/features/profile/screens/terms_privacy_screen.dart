import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  bool _isEnglish = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEnglish ? 'Terms & Privacy' : 'नियम र गोपनीयता',
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildLanguageToggle(),
            const SizedBox(height: 32),
            _buildHeader(
              _isEnglish ? 'Terms of Service' : 'सेवाका सर्तहरू',
              _isEnglish ? 'Last Updated: April 2024' : 'अन्तिम अपडेट: अप्रिल २०२४',
            ),
            const SizedBox(height: 24),
            _buildSection(
              num: '1',
              title: _isEnglish ? 'Introduction' : 'परिचय',
              content: _isEnglish
                  ? 'By accessing or using the Khozna platform, you agree to be bound by these Terms of Service. Khozna provides a digital environment to connect property owners with potential tenants or buyers in Nepal.'
                  : 'खोज्ना प्रयोग गरेर, तपाईं यी सेवाका सर्तहरू पालना गर्न सहमत हुनुहुन्छ। खोज्नाले नेपालका घरधनी र कोठा खोज्नेहरूलाई जोड्ने डिजिटल माध्यम प्रदान गर्दछ।',
            ),
            _buildSection(
              num: '2',
              title: _isEnglish ? 'Platform Scope' : 'प्लेटफर्मको क्षेत्र',
              content: _isEnglish
                  ? 'Khozna acts strictly as a bridge and facilitator. We do not participate in, control, or take responsibility for the actual rental agreements, payments, or physical handovers between users.'
                  : 'खोज्ना एउटा माध्यम र सहजकर्ता मात्र हो। हामी प्रयोगकर्ताहरू बीचको सम्झौता, भुक्तानी, वा भौतिक लेनदेनमा सहभागी हुँदैनौँ र यसको जिम्मेवारी पनि लिँदैनौं।',
            ),
            _buildSection(
              num: '3',
              title: _isEnglish ? 'Verification Duty' : 'प्रमाणीकरण कर्तव्य',
              content: _isEnglish
                  ? 'It is the sole responsibility of the seeker to verify the legal status of the property and the identity of the owner. Similarly, owners must verify seekers.'
                  : 'घर वा कोठाको कानुनी स्थिति र धनीको पहिचान प्रमाणित गर्ने पूर्ण जिम्मेवारी ग्राहकको हुनेछ। त्यसैगरी, धनीले पनि ग्राहकको पहिचान प्रमाणित गर्नुपर्नेछ।',
            ),
            _buildHighlightSection(
              title: _isEnglish
                  ? 'CRITICAL: Limitation of Liability'
                  : 'महत्त्वपूर्ण: उत्तरदायित्वको सीमा',
              content: _isEnglish
                  ? 'Khozna provides the platform "as-is". We are NOT liable for any financial losses, fraud, or disputes. \n\nIMPORTANT: Khozna does NOT initiate police reports or legal cases for users. You must contact Nepal Police independently for any disputes.'
                  : 'खोज्नाले यो प्लेटफर्म "जस्ताको तस्तै" उपलब्ध गराउँछ। हामी कुनै पनि आर्थिक हानि, ठगी वा विवादको लागि जिम्मेवार छैनौं। \n\nमहत्त्वपूर्ण: खोज्नाले प्रयोगकर्ताको तर्फबाट प्रहरी प्रतिवेदन वा कानुनी मुद्दा सुरु गर्दैन। कुनै पनि विवादको लागि तपाईंले आफैँ नेपाल प्रहरीमा सम्पर्क गर्नुपर्नेछ।',
            ),
            _buildSection(
              num: '4',
              title: _isEnglish ? 'Moderation & Blocking' : 'परिमार्जन र ब्लकिङ',
              content: _isEnglish
                  ? 'Khozna reserves the right to block any user suspected of fraud or harassment. Blocking is our primary internal enforcement mechanism.'
                  : 'खोज्नाले ठगी वा दुर्व्यवहारको शंका लागेमा कुनै पनि प्रयोगकर्तालाई ब्लक गर्ने अधिकार सुरक्षित राख्छ। ब्लक गर्नु हाम्रो मुख्य आन्तरिक कारबाही प्रक्रिया हो।',
            ),
            _buildSection(
              num: '5',
              title: _isEnglish ? 'Intellectual Property' : 'बौद्धिक सम्पत्ति',
              content: _isEnglish
                  ? 'All digital assets, logos, and designs are the exclusive property of Khozna Private Limited.'
                  : 'सबै डिजिटल सम्पत्ति, लोगो र डिजाइनहरू खोज्ना प्राइभेट लिमिटेडको विशेष सम्पत्ति हुन्।',
            ),
            const SizedBox(height: 32),
            _buildHeader(
              _isEnglish ? 'Privacy Policy' : 'गोपनीयता नीति',
              _isEnglish
                  ? 'Your data security is our priority'
                  : 'तपाईंको डाटाको सुरक्षा हाम्रो प्राथमिकता हो',
            ),
            const SizedBox(height: 24),
            _buildSection(
              num: '6',
              title: _isEnglish ? 'Data Collection' : 'डाटा संकलन',
              content: _isEnglish
                  ? 'We collect minimal data: Your phone number, location, and listing photos for platform functionality.'
                  : 'हामी न्यूनतम डाटा मात्र संकलन गर्छौं: तपाईंको फोन नम्बर, स्थान (लोकेसन) र विज्ञापनका फोटोहरू।',
            ),
            _buildSection(
              num: '7',
              title: _isEnglish ? 'Data Sharing' : 'डाटा साझेदारी',
              content: _isEnglish
                  ? 'Your contact info is only revealed when you choose to message or call another user. We do not sell your data.'
                  : 'तपाईंले अर्को प्रयोगकर्तालाई म्यासेज वा कल गर्दा मात्र तपाईंको सम्पर्क जानकारी देखिनेछ। हामी तपाईंको डाटा बिक्री गर्दैनौं।',
            ),
            _buildSection(
              num: '8',
              title: _isEnglish ? 'Governing Law' : 'लागू हुने कानुन',
              content: _isEnglish
                  ? 'These terms are governed by the laws of Nepal. Any disputes shall be handled in the courts of Kathmandu.'
                  : 'यी सर्तहरू नेपालको कानुन बमोजिम लागू हुनेछन्। कुनै पनि विवादको समाधान काठमाडौंको अदालतमा गरिनेछ।',
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                _isEnglish
                    ? '© 2024 Khozna Private Limited\nAll Rights Reserved'
                    : '© २०२४ खोज्ना प्राइभेट लिमिटेड\nसबै अधिकार सुरक्षित',
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

  Widget _buildLanguageToggle() {
    return Center(
      child: Container(
        height: 45,
        width: 240,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(true, 'ENGLISH'),
            ),
            Expanded(
              child: _buildToggleButton(false, 'नेपाली'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool value, String label) {
    bool isSelected = _isEnglish == value;
    return GestureDetector(
      onTap: () => setState(() => _isEnglish = value),
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? AppTheme.brandColor : Colors.grey[500],
          ),
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
            style: GoogleFonts.mukta(
              fontSize: 15,
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
            style: GoogleFonts.mukta(
              fontSize: 14,
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
