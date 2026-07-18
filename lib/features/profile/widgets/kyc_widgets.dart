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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: AppTheme.brandColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
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
    final bool uploaded = image != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded
                ? const Color(0xFF86EFAC)
                : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Left icon/preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: uploaded
                  ? Image.file(
                      image!,
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSelfie
                            ? Icons.face_retouching_natural_rounded
                            : Icons.image_outlined,
                        color: Colors.grey[400],
                        size: 28,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uploaded ? 'Photo Uploaded' : title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: uploaded
                          ? const Color(0xFF15803D)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    uploaded ? 'Tap to change photo' : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Right action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: uploaded
                    ? const Color(0xFF22C55E)
                    : AppTheme.brandColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                uploaded ? 'Change' : 'Upload',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
    // Split label into English and Nepali parts if " (" exists
    final parts = label.split(' (');
    final englishLabel = parts[0];
    final nepaliLabel = parts.length > 1 ? '(${parts[1]}' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row above the field
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              englishLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
                letterSpacing: -0.1,
              ),
            ),
            if (nepaliLabel != null) ...[
              const SizedBox(width: 4),
              Text(
                nepaliLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[400],
                ),
              ),
            ],
            if (isVerified) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 11),
                    const SizedBox(width: 3),
                    Text(
                      'Verified',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Input field
        TextFormField(
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
            color: isVerified ? Colors.grey[500] : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $englishLabel',
            hintStyle: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: isVerified ? const Color(0xFFF9FAFB) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.brandColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF3F4F6), width: 1.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

