import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:khozna/core/guards/kyc_guard.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/formatters.dart';
import 'package:khozna/core/models/property_model.dart';
import 'favourite_button.dart';
import 'package:khozna/core/utils/app_notifiers.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final bool isOwnerView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final double? width;

  const PropertyCard({
    super.key,
    required this.property,
    this.isOwnerView = false,
    this.onEdit,
    this.onDelete,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOwnerView ? null : () async {
        HapticFeedback.lightImpact();
        final allowed = await KycGuard.check(context);
        if (!allowed) return;
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)));
        }
      },
      child: Container(
        width: width ?? 260,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF2F2F2)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 175,
                    width: double.infinity,
                    child: Hero(
                      tag: property.id,
                      child: KhoznaImage(
                        imageUrl: property.imageUrl,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, left: 10,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: bookedPropertiesStore,
                      builder: (context, bookedIds, _) {
                        final isBooked = property.status == 'booked';
                        final isPending = bookedIds.contains(property.id) || property.status == 'pending_approval';
                        if (!isBooked && !isPending && property.status != 'available') return const SizedBox.shrink();
                        return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: isBooked ? Colors.redAccent : (isPending ? Colors.orange : const Color(0xFF00C853)), borderRadius: BorderRadius.circular(30)), child: Text(isBooked ? 'BOOKED' : (isPending ? 'PENDING' : 'FOR RENT'), style: GoogleFonts.inter(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.w900, letterSpacing: 0.5)));
                      },
                    ),
                  ),
                  Positioned(top: 6, right: 10, child: FavouriteButton(propertyId: property.id)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E), letterSpacing: -0.5))),
                        const SizedBox(width: 4),
                        RichText(text: TextSpan(children: [TextSpan(text: '₹', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.brandColor)), TextSpan(text: PriceFormatter.format(property.price), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.brandColor))])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, color: AppTheme.brandColor, size: 14),
                        const SizedBox(width: 4),
                        Expanded(child: Text(property.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!isOwnerView) ...[
                          Expanded(child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property))), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text('Visit Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold)))),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => chat_page.ChatScreen(ownerId: property.ownerId, name: property.ownerName ?? 'Owner', avatar: property.ownerAvatar ?? '', online: true, isVerified: property.isOwnerVerified))), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.brandColor, side: const BorderSide(color: AppTheme.brandColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text('Message', style: GoogleFonts.inter(fontWeight: FontWeight.bold)))),
                        ] else ...[
                          Expanded(child: OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_note_rounded), label: const Text('Edit'), style: OutlinedButton.styleFrom(foregroundColor: Colors.blueGrey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Delete'), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
