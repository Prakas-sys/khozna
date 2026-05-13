import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/screens/add_property_screen.dart';

class PostPropertyIntroScreen extends StatelessWidget {
  const PostPropertyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 18),
            ),
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
                    const SizedBox(height: 32),
                    Text(
                      'KHOZNA मा लिस्टिङ गर्नुहोस्',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'आफ्नो प्रोपर्टीलाई १०/१० बनाउन यी चरणहरू पालना गर्नुहोस्।',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildStep(
                      stepNumber: 1,
                      title: 'आधारभूत विवरण (Basics)',
                      subtitle: 'तपाईंको प्रोपर्टी कुन ठाउँमा छ र कस्तो प्रकारको हो, बताउनुहोस्।',
                      icon: Icons.maps_home_work_rounded,
                    ),
                    _buildStep(
                      stepNumber: 2,
                      title: 'प्रोपर्टीको विशेषता (Features)',
                      subtitle: 'बेडरुम, बाथरूम संख्या र क्षेत्रफलको बारेमा जानकारी दिनुहोस्।',
                      icon: Icons.bed_rounded,
                    ),
                    _buildStep(
                      stepNumber: 3,
                      title: 'सुविधाहरू र फोटो (Media)',
                      subtitle: 'कम्तिमा ५ वटा राम्रो फोटो र उपलब्ध सुविधाहरू थप्नुहोस्।',
                      icon: Icons.camera_rounded,
                    ),
                    _buildStep(
                      stepNumber: 4,
                      title: 'AI विवरण (AI Description)',
                      subtitle: 'हाम्रो एआईले तपाईंको लागि उत्कृष्ट शीर्षक र विवरण लेख्नेछ।',
                      icon: Icons.auto_awesome_rounded,
                    ),
                    _buildStep(
                      stepNumber: 5,
                      title: 'भाडा र भुक्तानी (Pricing)',
                      subtitle: 'भाडा तोक्नुहोस् र पैसा लिने खाता नम्बर राख्नुहोस्।',
                      icon: Icons.payments_rounded,
                      isLast: true,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // CTA Button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
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

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isLast = false,
  }) {
    final Color color = AppTheme.brandColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFloatingElement(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 1 + index),
      builder: (context, value, child) {
        double offset = (10 * (1 - value)) + (index * 5);
        return Positioned(
          top: 10 + (index * 15),
          right: 10 + offset,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.brandColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
