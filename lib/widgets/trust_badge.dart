import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrustBadge extends StatelessWidget {
  final String badge;
  final double? fontSize;
  final bool showLabel;

  const TrustBadge({
    super.key,
    required this.badge,
    this.fontSize,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (badge.toLowerCase()) {
      case 'top':
        color = const Color(0xFFFFD700); // Gold
        icon = Icons.stars_rounded;
        label = 'उत्कृष्ट (Elite Owner)';
        break;
      case 'trusted':
        color = const Color(0xFF00A3FF); // Khozna Blue
        icon = Icons.verified_rounded;
        label = 'प्रमाणित (Verified Owner)';
        break;
      case 'new':
      default:
        color = Colors.grey[400]!;
        icon = Icons.person_outline_rounded;
        label = 'नयाँ सदस्य (New Member)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: (fontSize ?? 12) + 2),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.mukta(
                color: color,
                fontSize: fontSize ?? 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
