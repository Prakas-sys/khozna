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
              _isEnglish
                  ? 'Last Updated: April 2026'
                  : 'अन्तिम अपडेट: अप्रिल २०२६',
            ),
            const SizedBox(height: 24),
            _buildSection(
              num: '1',
              title: _isEnglish ? 'Introduction' : 'परिचय',
              content: _isEnglish
                  ? 'By accessing or using the KHOZNA platform, you agree to be bound by these Terms of Service. KHOZNA provides a digital environment to connect property owners with potential tenants or buyers in Nepal.'
                  : 'खोज्न प्रयोग गरेर, तपाईं यी सेवाका सर्तहरू पालना गर्न सहमत हुनुहुन्छ। खोज्नले नेपालका घरधनी र कोठा खोज्नेहरूलाई जोड्ने डिजिटल माध्यम प्रदान गर्दछ।',
            ),
            _buildSection(
              num: '2',
              title: _isEnglish ? 'Platform Scope' : 'प्लेटफर्मको क्षेत्र',
              content: _isEnglish
                  ? 'KHOZNA acts strictly as a bridge and facilitator. We do not participate in, control, or take responsibility for the actual rental agreements, payments, or physical handovers between users.'
                  : 'खोज्न एउटा माध्यम र सहजकर्ता मात्र हो। हामी प्रयोगकर्ताहरू बीचको सम्झौता, भुक्तानी, वा भौतिक लेनदेनमा सहभागी हुँदैनौँ र यसको जिम्मेवारी पनि लिँदैनौं।',
            ),
            _buildSection(
              num: '3',
              title: _isEnglish ? 'User Safety & Verification' : 'प्रयोगकर्ता सुरक्षा र प्रमाणीकरण',
              content: _isEnglish
                  ? 'It is the sole responsibility of the seeker to verify the legal status of the property and the identity of the owner. NEVER pay any "booking fee" or advance without visiting the property and meeting the owner in person.'
                  : 'कोठा वा घर हेर्न जानु अघि कुनै पनि "बुकिङ शुल्क" वा एडभान्स रकम भुक्तानी नगर्नुहोस्। घरधनीको पहिचान र घरको कानुनी कागजातहरू आफैँले प्रमाणित गर्नुहोला।',
            ),
            _buildHighlightSection(
              title: _isEnglish
                  ? 'CRITICAL: Limitation of Liability'
                  : 'महत्त्वपूर्ण: उत्तरदायित्वको सीमा',
              content: _isEnglish
                  ? 'KHOZNA provides the platform "as-is". We are NOT liable for any financial losses, fraud, or disputes. \n\nIMPORTANT: KHOZNA does NOT initiate police reports or legal cases for users. You must contact Nepal Police independently for any disputes.'
                  : 'खोज्नले यो प्लेटफर्म "जस्ताको तस्तै" उपलब्ध गराउँछ। हामी कुनै पनि आर्थिक हानि, ठगी वा विवादको लागि जिम्मेवार छैनौं। \n\nमहत्त्वपूर्ण: खोज्नले प्रयोगकर्ताको तर्फबाट प्रहरी प्रतिवेदन वा कानुनी मुद्दा सुरु गर्दैन। कुनै पनि विवादको लागि तपाईंले आफैँ नेपाल प्रहरीमा सम्पर्क गर्नुपर्नेछ।',
            ),
            _buildSection(
              num: '4',
              title: _isEnglish
                  ? 'Moderation & Safety Enforcement'
                  : 'परिमार्जन र सुरक्षा प्रवर्तन',
              content: _isEnglish
                  ? 'KHOZNA reserves the right to permanently block any user suspected of fraud, harassment, or providing misleading information. Your safety is our concern, but your vigilance is your primary defense.'
                  : 'खोज्नले प्रयोगकर्ताहरूको सुरक्षालाई उच्च प्राथमिकता दिन्छ। ठगी, दुर्व्यवहार वा गलत जानकारी दिने जो कोहीलाई हामी तुरुन्तै र स्थायी रूपमा ब्लक गर्ने अधिकार सुरक्षित राख्छौं।',
            ),
            _buildSection(
              num: '5',
              title: _isEnglish ? 'Intellectual Property' : 'बौद्धिक सम्पत्ति',
              content: _isEnglish
                  ? 'All digital assets, logos, and designs are the exclusive property of KHOZNA Private Limited.'
                  : 'सबै डिजिटल सम्पत्ति, लोगो र डिजाइनहरू खोज्न प्राइभेट लिमिटेडको विशेष सम्पत्ति हुन्।',
            ),
            const SizedBox(height: 32),
            _buildHeader(
              _isEnglish ? 'Privacy Policy' : 'गोपनीयता नीति',
              _isEnglish
                  ? 'Last Updated: May 13, 2026'
                  : 'अन्तिम अपडेट: मे १३, २०२६',
            ),
            const SizedBox(height: 16),
            Text(
              _isEnglish
                  ? 'Khozna ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share information when you use our mobile application.'
                  : 'खोज्न तपाईंको गोपनीयताको रक्षा गर्न प्रतिबद्ध छ। यस नीतिले तपाईंले हाम्रो मोबाइल एप प्रयोग गर्दा हामी कसरी जानकारी संकलन, प्रयोग र साझा गर्छौं भनेर वर्णन गर्दछ।',
              style: GoogleFonts.mukta(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              num: '6',
              title: _isEnglish ? 'Information We Collect' : 'हामीले संकलन गर्ने जानकारी',
              content: _isEnglish
                  ? '• Personal Info: Name, phone number, email address, and payment info (eSewa/Khalti).\n• Location Data: Precise GPS data to verify properties and provide nearby searches (required for KYC).\n• Media: Photos/videos of properties, profile pictures, and identity documents (ID/Student cards) for KYC.\n• Usage Data: Interactions with the App (searches, AI chat history, property views).'
                  : '• व्यक्तिगत जानकारी: नाम, फोन नम्बर, इमेल, र भुक्तानी विवरण (eSewa/Khalti)।\n• स्थान डाटा: सम्पत्ति प्रमाणित गर्न र नजिकैको खोजहरूको लागि सही GPS डाटा।\n• मिडिया: सम्पत्तिका फोटो/भिडियोहरू, र KYC को लागि परिचयपत्रहरू।\n• उपयोग डाटा: एपमा गरिएका गतिविधिहरू (खोज, म्यासेज, आदि)।',
            ),
            _buildSection(
              num: '7',
              title: _isEnglish ? 'How We Use Your Info' : 'तपाईंको जानकारीको प्रयोग',
              content: _isEnglish
                  ? '• Verification: To ensure safety by verifying properties and owner identities.\n• Communication: To facilitate chat and AI assistance.\n• Payments: To process transactions and owner payouts.\n• Security: To detect and prevent fraud, scams, and unauthorized access.'
                  : '• प्रमाणीकरण: सुरक्षा सुनिश्चित गर्न घरधनी र घर प्रमाणित गर्न।\n• सञ्चार: च्याट र AI सहायता प्रदान गर्न।\n• भुक्तानी: कारोबार र भुक्तानी प्रक्रिया गर्न।\n• सुरक्षा: ठगी र अनधिकृत पहुँच रोक्न।',
            ),
            _buildSection(
              num: '8',
              title: _isEnglish ? 'Data Sharing & Disclosure' : 'डाटा साझेदारी',
              content: _isEnglish
                  ? 'We do not sell your personal data. Your contact info (phone number) is shared ONLY when a visit is accepted or a booking is confirmed. Identity documents are strictly for internal KYC and are NEVER visible to other users.'
                  : 'हामी तपाईंको डाटा बिक्री गर्दैनौं। तपाईंको फोन नम्बर बुकिङ वा भिजिट स्वीकृत भएपछि मात्र साझा गरिन्छ। परिचयपत्रहरू आन्तरिक KYC को लागि मात्र हुन् र अरूलाई देखाइँदैन।',
            ),
            _buildSection(
              num: '9',
              title: _isEnglish ? 'Data Security' : 'डाटा सुरक्षा',
              content: _isEnglish
                  ? 'We implement industry-standard security measures, including screenshot blocking on sensitive data and secure data transmission, to protect your information.'
                  : 'तपाईंको जानकारी सुरक्षित राख्न हामीले संवेदनशील डाटामा स्क्रिनसट ब्लक गर्ने र सुरक्षित डाटा ट्रान्समिसन जस्ता सुरक्षा उपायहरू लागू गरेका छौं।',
            ),
            _buildSection(
              num: '10',
              title: _isEnglish ? 'Your Rights' : 'तपाईंका अधिकारहरू',
              content: _isEnglish
                  ? 'You have the right to access, update, or delete your personal information at any time via the "Edit Profile" section of the App.'
                  : 'तपाईंलाई एपको "Edit Profile" खण्ड मार्फत कुनै पनि समय आफ्नो व्यक्तिगत जानकारी हेर्न, परिमार्जन गर्न वा मेटाउने अधिकार छ।',
            ),
            _buildSection(
              num: '11',
              title: _isEnglish ? 'Contact Us' : 'सम्पर्क गर्नुहोस्',
              content: _isEnglish
                  ? 'If you have any questions about this Privacy Policy, please contact us at support@khozna.com.'
                  : 'यस गोपनीयता नीतिको बारेमा कुनै प्रश्न भएमा, कृपया support@khozna.com मा सम्पर्क गर्नुहोस्।',
            ),
            _buildSection(
              num: '12',
              title: _isEnglish ? 'Governing Law' : 'लागू हुने कानुन',
              content: _isEnglish
                  ? 'These terms are governed by the laws of Nepal. Any disputes shall be handled in the courts of Kathmandu.'
                  : 'यी सर्तहरू नेपालको कानुन बमोजिम लागू हुनेछन्। कुनै पनि विवादको समाधान काठमाडौंको अदालतमा गरिनेछ।',
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                _isEnglish
                    ? '© 2026 KHOZNA Private Limited\nAll Rights Reserved'
                    : '© २०२६ खोज्न प्राइभेट लिमिटेड\nसबै अधिकार सुरक्षित',
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
            Expanded(child: _buildToggleButton(true, 'ENGLISH')),
            Expanded(child: _buildToggleButton(false, 'नेपाली')),
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
                  ),
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

  Widget _buildHighlightSection({
    required String title,
    required String content,
  }) {
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
