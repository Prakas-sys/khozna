import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/guards/kyc_guard.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/formatters.dart';
import 'favourite_button.dart';
import 'skeleton_card.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/property_model.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final bool isOwnerView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int views;
  final double? width;

  const PropertyCard({
    super.key,
    required this.property,
    this.isOwnerView = false,
    this.onEdit,
    this.onDelete,
    this.views = 0,
    this.width,
  });

  // Getters to bridge the original design code with the Property model
  String get id => property.id;
  String get title => property.title;
  String get location => property.location;
  String get price => property.price;
  int get bedrooms => property.bedrooms;
  int get bathrooms => property.bathrooms;
  String get area => property.area;
  String get floor => property.floor;
  String get description => property.description;
  String get ownerId => property.ownerId;
  String get ownerName => property.ownerName ?? 'Khozna User';
  String get ownerAvatar => property.ownerAvatar ?? '';
  bool get isOwnerVerified => property.isOwnerVerified ?? false;
  String get status => property.status;
  List<String> get amenities => property.amenities;
  List<String> get houseRules => property.houseRules;
  String get imageUrl => property.imageUrl;
  List<String> get images => property.images;
  String get category => property.category;
  String get landmark => property.landmark;
  double? get latitude => property.latitude;
  double? get longitude => property.longitude;
  List<dynamic> get nearbyLandmarks => property.nearbyLandmarks;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOwnerView
          ? null // Owners can always tap their own cards
          : () async {
              HapticFeedback.lightImpact();
              final allowed = await KycGuard.check(context);
              if (!allowed) return;
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailsScreen(
                      property: property,
                    ),
                  ),
                );
              }
            },
      child: Container(
        width: width ?? 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF2F2F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image (unchanged height) ---
              Stack(
                children: [
                  SizedBox(
                    height: 175, // Reduced from 180 to perfectly fit 285px parent without overflow
                    width: double.infinity,
                    child: Hero(
                      tag: id,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl.isNotEmpty
                            ? imageUrl
                            : (images.isNotEmpty ? images[0] : ''),
                        fit: BoxFit.cover,
                        memCacheWidth: 600, // Optimize memory for lists
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                _buildImagePlaceholder(),
                                // Subtly blurring overlay for the 'Instagram' feel
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(color: Colors.white.withOpacity(0)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF9FAFB),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_rounded,
                                color: AppTheme.brandColor.withOpacity(0.1),
                                size: 54,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Khozna Home',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Status Badges
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        ValueListenableBuilder<Set<String>>(
                          valueListenable: bookedPropertiesStore,
                          builder: (context, bookedIds, _) {
                            final isBooked = status == 'booked';
                            final isPending = bookedIds.contains(id) || status == 'pending_approval';
                            
                            if (!isBooked && !isPending && status != 'available') return const SizedBox.shrink();

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? Colors.redAccent
                                    : (isPending ? Colors.orange : const Color(0xFF00C853)),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                isBooked 
                                    ? 'BOOKED' 
                                    : (isPending ? 'PENDING' : 'FOR RENT'),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Favourite button
                  Positioned(
                    top: 6,
                    right: 10,
                    child: FavouriteButton(propertyId: id),
                  ),
                  // Views Badge (Owner Only)
                  if (isOwnerView)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.remove_red_eye_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              views > 999
                                  ? '${(views / 1000).toStringAsFixed(1)}k'
                                  : '$views',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // --- Content below image ---
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 7), // Restored to your original 7px bottom padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800, // Semi-solid / Stronger look
                              color: const Color(0xFF1A1A2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.brandColor,
                                  letterSpacing: 0.3, // Micro-gap for perfect alignment
                                ),
                              ),
                              TextSpan(
                                text: PriceFormatter.format(price),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandColor,
                                ),
                              ),
                              WidgetSpan(
                                child: Transform.translate(
                                  offset: const Offset(1, -2.5), // Pixel-perfect alignment
                                  child: Text(
                                    '/mo',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2), // Reduced for tighter look
                    _buildAmenityItems(),
                    const SizedBox(height: 4), // Reduced to compensate for glass border thickness
                    // Action Buttons
                    Row(
                      children: [
                        if (!isOwnerView) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(2), // Thin glass border thickness
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.brandColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    final allowed = await KycGuard.check(context);
                                    if (!allowed) return;
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PropertyDetailsScreen(
                                            property: property,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.directions_walk_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Visit Now',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => chat_page.ChatScreen(
                                        ownerId: ownerId,
                                        name: ownerName ?? 'Khozna User',
                                        avatar: ownerAvatar ?? '',
                                        isVerified: isOwnerVerified ?? false,
                                        online: true,
                                        phone: '+977 9801234567',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.brandColor,
                                side: const BorderSide(
                                  color: AppTheme.brandColor,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      for (double i = -0.3; i <= 0.3; i += 0.3)
                                        for (double j = -0.3; j <= 0.3; j += 0.3)
                                          if (i != 0 || j != 0)
                                            Transform.translate(
                                              offset: Offset(i, j),
                                              child: SvgPicture.asset(
                                                'assets/icons/message.svg',
                                                width: 18,
                                                height: 18,
                                                colorFilter: const ColorFilter.mode(
                                                  AppTheme.brandColor,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            ),
                                      SvgPicture.asset(
                                        'assets/icons/message.svg',
                                        width: 18,
                                        height: 18,
                                        colorFilter: const ColorFilter.mode(
                                          AppTheme.brandColor,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Message',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                size: 20,
                              ),
                              label: const Text('Edit Listing'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueGrey[700],
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                              ),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildAmenityItems() {
    // Top priority icons for the card
    final Map<String, IconData> featureIcons = {
      // Amenities
      'water_melamchi': Icons.water_drop_outlined,
      'parking_bike': Icons.pedal_bike_outlined,
      'parking_car': Icons.directions_car_outlined,
      'sunny_room': Icons.wb_sunny_outlined,
      'hot_water': Icons.hot_tub_outlined,
      'waste_mgmt': Icons.delete_outline,
      'peaceful': Icons.nature_people_outlined,
      'internet': Icons.wifi_outlined,
      'kitchen': Icons.kitchen_outlined,
      'attached_bathroom': Icons.bathroom_outlined,
      // House Rules
      'family_only': Icons.family_restroom_outlined,
      'boys_allowed': Icons.man,
      'girls_allowed': Icons.woman,
      'pets_allowed': Icons.pets,
    };

    List<Widget> items = [];

    // 1. Build Location Widget
    Widget locationWidget = Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place_outlined,
            color: AppTheme.brandColor,
            size: 13,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    // 2. Build Amenities (Max 3 total items)
    List<Widget> amenityItems = [];
    int count = 0;

    // Priority 1: Bedrooms
    if (bedrooms > 0) {
      amenityItems.add(_amenityIcon(Icons.bed_outlined, '$bedrooms Bed'));
      count++;
    }

    // Combine amenities and house rules for display
    final combinedFeatures = [...amenities, ...houseRules];

    for (var feature in combinedFeatures) {
      if (count >= 3) break; // Maximum 3 items allowed
      if (featureIcons.containsKey(feature)) {
        if (amenityItems.isNotEmpty) {
          amenityItems.add(const SizedBox(width: 12));
        }
        amenityItems.add(
          _amenityIcon(featureIcons[feature]!, _getShortLabel(feature)),
        );
        count++;
      }
    }

    return SizedBox(
      height: 25,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          locationWidget,
          if (amenityItems.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: amenityItems),
        ],
      ),
    );
  }

  String _getShortLabel(String key) {
    switch (key) {
      case 'water_melamchi':
        return 'Water';
      case 'water_boring':
        return 'Boring';
      case 'parking_bike':
        return 'Bike';
      case 'parking_car':
        return 'Car';
      case 'sunny_room':
        return 'Sunny';
      case 'hot_water':
        return 'Hot';
      case 'waste_mgmt':
        return 'Waste';
      case 'peaceful':
        return 'Quiet';
      case 'internet':
        return 'Wifi';
      case 'kitchen':
        return 'Kitchen';
      case 'family_only':
        return 'Family';
      case 'boys_allowed':
        return 'Boys';
      case 'girls_allowed':
        return 'Girls';
      case 'pets_allowed':
        return 'Pets';
      default:
        return '';
    }
  }

  Widget _amenityIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.brandColor, size: 14),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            color: Colors.grey[700],
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 175,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey[300],
          size: 40,
        ),
      ),
    );
  }
}
