import 'package:khozna/widgets/khozna_image.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';

class KycSectionHeader extends StatelessWidget {
  final String title;
  const KycSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1A1A2E),
        letterSpacing: -0.3,
      ),
    );
  }
}

class KycStepButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const KycStepButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class DashRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashRectPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(
      RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(20)),
    );

    Path dashPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CitizenshipFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
    String formatted = '';

    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
      if (formatted.length >= 14) break;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhotoUploadBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final File? image;
  final VoidCallback onTap;
  final bool isSelfie;

  const PhotoUploadBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
    this.isSelfie = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashRectPainter(
          color: image != null ? Colors.green.withOpacity(0.5) : AppTheme.brandColor.withOpacity(0.4), 
          gap: 6,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: image != null ? Colors.green.withOpacity(0.04) : AppTheme.brandColor.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    image!,
                    height: 120,
                    width: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Uploaded Successfully',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelfie ? Icons.face_retouching_natural_rounded : Icons.camera_alt_rounded,
                    color: AppTheme.brandColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class KycTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isVerified;
  final String? providerLogo;
  final VoidCallback? onChanged;

  const KycTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.isVerified = false,
    this.providerLogo,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: isVerified,
        enabled: !isVerified,
        onChanged: (v) => onChanged?.call(),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isVerified ? Colors.grey[600] : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          floatingLabelStyle: GoogleFonts.inter(
            color: AppTheme.brandColor,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: providerLogo != null
              ? Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: KhoznaImage(imageUrl: providerLogo!, width: 22, height: 22),
                )
              : Icon(
                  icon,
                  color: controller.text.isNotEmpty ? AppTheme.brandColor : Colors.grey[400],
                  size: 20,
                ),
          suffixIcon: isVerified
              ? Container(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Verified',
                        style: GoogleFonts.inter(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.green[600],
                        size: 16,
                      ),
                    ],
                  ),
                )
              : null,
          filled: true,
          fillColor: isVerified
              ? Colors.grey[50]
              : (controller.text.isNotEmpty ? Colors.blue[50]!.withOpacity(0.3) : Colors.white),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: controller.text.isNotEmpty ? AppTheme.brandColor.withOpacity(0.3) : Colors.grey.shade200,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppTheme.brandColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
        ),
      ),
    );
  }
}

