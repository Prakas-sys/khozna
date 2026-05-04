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
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Header
                    Text(
                      'It\'s easy to list\non Khozna',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.1,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildStep(
                      stepNumber: '1',
                      title: 'Basic Details',
                      subtitle: 'Tell us where it is and what type of property you have.',
                      icon: Icons.maps_home_work_outlined,
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    _buildStep(
                      stepNumber: '2',
                      title: 'Property Features',
                      subtitle: 'Share how many beds, baths, and the area size.',
                      icon: Icons.bed_outlined,
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    _buildStep(
                      stepNumber: '3',
                      title: 'Amenities',
                      subtitle: 'Let guests know what facilities are included.',
                      icon: Icons.wifi_outlined,
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    _buildStep(
                      stepNumber: '4',
                      title: 'Media',
                      subtitle: 'Add 5 or more photos and a video reel.',
                      icon: Icons.camera_alt_outlined,
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    _buildStep(
                      stepNumber: '5',
                      title: 'AI Description',
                      subtitle: 'Our AI will craft a perfect title and description.',
                      icon: Icons.auto_awesome_outlined,
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    _buildStep(
                      stepNumber: '6',
                      title: 'Finish & Publish',
                      subtitle: 'Set a starting price, rules, and go live.',
                      icon: Icons.publish_outlined,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // CTA Button — pinned at bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
              ),
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
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Get started',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$stepNumber  ',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      TextSpan(
                        text: title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Icon Box (Right aligned)
          Icon(icon, color: const Color(0xFF4B5563), size: 36),
        ],
      ),
    );
  }
}
