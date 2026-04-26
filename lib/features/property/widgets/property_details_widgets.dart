import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';

class DetailSectionTitle extends StatelessWidget {
  final String title;
  const DetailSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
                  style: GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryTextColor,
      ),
    );
  }
}

class PropertyStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const PropertyStatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.08),
                accentColor.withOpacity(0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.4),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class LocationInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const LocationInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.brandColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                value,
                                                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RuleRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const RuleRow({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class NearbyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String distance;

  const NearbyItem({
    super.key,
    required this.icon,
    required this.title,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
          ),
          const Spacer(),
          Text(
            distance,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassCircle extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final double opacity;
  final double padding;

  const GlassCircle({
    super.key,
    this.icon,
    this.child,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.opacity = 0.2,
    this.padding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: child ?? Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const NavArrow({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
