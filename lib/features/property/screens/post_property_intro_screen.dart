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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Header
                      Text(
                        'Khozna मा सम्पत्ति\nराख्न एकदम सजिलो छ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '३ मुख्य चरणहरूमा तपाईंको प्रोपर्टी प्रकाशित गर्नुहोस्',
                        style: GoogleFonts.mukta(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildStep(
                        stepNumber: '1',
                        title: 'तपाईंको ठाउँको बारेमा बताउनुहोस्',
                        subtitle: 'Tell us about your place (Category, Location, Basics)',
                        icon: Icons.maps_home_work_rounded,
                        color: AppTheme.brandColor,
                      ),
                      _buildConnector(),
                      _buildStep(
                        stepNumber: '2',
                        title: 'आकर्षक बनाउनुहोस्',
                        subtitle: 'Make it stand out (Photos, Video, Amenities, AI Desc)',
                        icon: Icons.auto_awesome_rounded,
                        color: Colors.pink,
                      ),
                      _buildConnector(),
                      _buildStep(
                        stepNumber: '3',
                        title: 'अन्तिम तयारी र प्रकाशन',
                        subtitle: 'Finish up (Pricing, House Rules, Payout & Publish)',
                        icon: Icons.rocket_launch_rounded,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // CTA Button — pinned at bottom
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
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
                    elevation: 4,
                    shadowColor: AppTheme.brandColor.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'सुरु गर्नुहोस्',
                    style: GoogleFonts.mukta(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        // Step Number
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.mukta(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        // Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(
        width: 1.5,
        height: 24,
        color: Colors.grey[200],
      ),
    );
  }
}
