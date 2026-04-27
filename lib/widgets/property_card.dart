import 'package:flutter/material.dart';
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
                    height: 170,
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
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                                                                          Expanded(child: Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E), letterSpacing: -0.5))),
                          const SizedBox(width: 4),
                          RichText(text: TextSpan(children: [TextSpan(text: '₹', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.brandColor)), TextSpan(text: PriceFormatter.format(property.price), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.brandColor))])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildLocationAndAmenities(context),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (!isOwnerView) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  final allowed = await KycGuard.check(context);
                                  if (!allowed) return;
                                  if (context.mounted) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.directions_walk_rounded, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text('Visit Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  final allowed = await KycGuard.check(context);
                                  if (!allowed) return;
                                  if (context.mounted) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => chat_page.ChatScreen(ownerId: property.ownerId, name: property.ownerName ?? 'Owner', avatar: property.ownerAvatar ?? '', online: true, isVerified: property.isOwnerVerified)));
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.brandColor,
                                  side: const BorderSide(color: AppTheme.brandColor, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [AppTheme.brandColor, Color(0xFF005A7A)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: SvgPicture.asset(
                                        'assets/icons/message.svg',
                                        width: 18,
                                        height: 18,
                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('Message', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.brandColor)),
                                  ],
                                ),
                              ),
                            ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationAndAmenities(BuildContext context) {
    IconData _getIcon(String k) {
      final key = k.toLowerCase().trim();
      if (key.contains('wifi') || key.contains('internet')) return Icons.wifi;
      if (key.contains('water')) return Icons.water_drop_outlined;
      if (key.contains('parking')) return Icons.directions_car_filled_outlined;
      if (key.contains('sunny')) return Icons.wb_sunny_outlined;
      if (key.contains('cctv') || key.contains('security')) return Icons.videocam_outlined;
      if (key.contains('balcony')) return Icons.balcony_outlined;
      if (key.contains('hot water')) return Icons.hot_tub_outlined;
      if (key.contains('bath')) return Icons.bathroom_outlined;
      if (key.contains('family')) return Icons.family_restroom_outlined;
      if (key.contains('kitchen')) return Icons.kitchen_outlined;
      return Icons.check_circle_outline_rounded;
    }

    List<Widget> amenityItems = [];
    int count = 0;
    final combinedFeatures = [...property.amenities, ...property.houseRules];

    for (var feature in combinedFeatures) {
      if (count >= 2) break;
      IconData icon = _getIcon(feature);
      String label = _getShortLabel(feature.toLowerCase().trim());
      
      amenityItems.add(const SizedBox(width: 10));
      amenityItems.add(_amenityIcon(icon, label));
      count++;
    }

    return Row(
      children: [
        const Icon(Icons.place_outlined, color: AppTheme.brandColor, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            property.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ),
        if (amenityItems.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: amenityItems),
      ],
    );
  }

  Widget _amenityIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.brandColor, size: 14),
        const SizedBox(height: 1),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 8, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getShortLabel(String key) {
    final k = key.toLowerCase().trim();
    if (k.contains('water')) return 'Water';
    if (k.contains('wifi') || k.contains('internet')) return 'Internet';
    if (k.contains('parking')) return 'Parking';
    if (k.contains('sunny')) return 'Sunny';
    if (k.contains('cctv')) return 'CCTV';
    if (k.contains('balcony')) return 'Balcony';
    if (k.contains('hot water')) return 'Hot Water';
    if (k.contains('bath')) return 'Bath';
    if (k.contains('family')) return 'Family';
    if (k.contains('kitchen')) return 'Kitchen';
    
    if (key.isEmpty) return '';
    String formatted = key.replaceAll('_', ' ');
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}
