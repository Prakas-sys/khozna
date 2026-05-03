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
                        'Khozna मा सम्पत्ति\nराख्न सजिलो छ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '६ सजिलो चरणमा तपाईंको सम्पत्ति राख्नुहोस्',
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildStep(
                        stepNumber: '1',
                        title: 'प्रकार र शीर्षक',
                        subtitle: 'Type & Title',
                        icon: Icons.home_rounded,
                        color: AppTheme.brandColor,
                      ),
                      _buildConnector(),
                      _buildStep(
                        stepNumber: '2',
                        title: 'ठाउँ / लोकेशन',
                        subtitle: 'Location & GPS',
                        icon: Icons.location_on_rounded,
                        color: Colors.blue,
                      ),
                      _buildConnector(),
                      _buildStep(
                        stepNumber: '3',
                        title: 'भाडा र विवरण',
                        subtitle: 'Price & Details',
                        icon: Icons.currency_rupee_rounded,
                        color: Colors.green,
                      ),
                      _buildConnector(),
                      _buildStep(
                        stepNumber: '4',
                        title: 'सुविधाहरू',
                        subtitle: 'Amenities',
                        icon: Icons.wifi_rounded,
                        color: Colors.orange,
                      ),
                      _buildConnector(),
                      _buildStep(
                        stepNumber: '5',
                        title: 'नियमहरू',
                        subtitle: 'House Rules',
                        icon: Icons.rule_rounded,
                        color: Colors.purple,
                      ),
                      _buildConnector(),
                      _buildStep(
                        stepNumber: '6',
                        title: 'फोटो र प्रकाशित',
                        subtitle: 'Photos & Publish',
                        icon: Icons.camera_alt_rounded,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // CTA Button — pinned at bottom
              SizedBox(
                width: double.infinity,
                height: 62,
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'सुरु गर्नुहोस्',
                    style: GoogleFonts.mukta(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
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
