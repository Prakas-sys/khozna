import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/formatters.dart';
import 'favourite_button.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/guards/auth_guard.dart';

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
  String get ownerName => property.ownerName;
  String get ownerAvatar => property.ownerAvatar;
  bool get isOwnerVerified => property.isOwnerVerified;
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
              if (!AuthGuard.checkAuth(
                context,
                title: 'View Details',
                message: 'Log in to view complete details of this property.',
              )) {
                return;
              }
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailsScreen(property: property),
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
                    height:
                        175, // Reduced from 180 to perfectly fit 285px parent without overflow
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
                                    filter: ImageFilter.blur(
                                      sigmaX: 5,
                                      sigmaY: 5,
                                    ),
                                    child: Container(
                                      color: Colors.white.withOpacity(0),
                                    ),
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
                            final isPending =
                                bookedIds.contains(id) ||
                                status == 'pending_approval';

                            if (!isBooked &&
                                !isPending &&
                                status != 'available') {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? Colors.redAccent
                                    : (isPending
                                          ? Colors.orange
                                          : const Color(0xFF00C853)),
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
                              property.views > 999
                                  ? '${(property.views / 1000).toStringAsFixed(1)}k'
                                  : '${property.views}',
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
                padding: const EdgeInsets.fromLTRB(
                  14,
                  6,
                  14,
                  5,
                ), // Reduced from 7 to fix overflow warning
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
                              fontSize: 16.3,
                              fontWeight:
                                  FontWeight.w800, // Semi-solid / Stronger look
                              color: const Color(0xFF1A1A2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.translate(
                          offset: const Offset(
                            0,
                            -0.5,
                          ), // Subtle shift for price/symbol
                          child: RichText(
                            text: TextSpan(
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Transform.translate(
                                    offset: const Offset(0, -1.5), // Pushed even higher per user request
                                    child: SvgPicture.asset(
                                      'assets/icons/vector of ruppes.svg',
                                      width: 14.5,
                                      height: 14.5,
                                      colorFilter: const ColorFilter.mode(
                                        AppTheme.brandColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                                const WidgetSpan(
                                  child: SizedBox(width: 2), // Tighter spacing per user request
                                ),
                                TextSpan(
                                  text: (() {
                                    final val = PriceFormatter.format(
                                      property.priceMonth > 0
                                          ? property.priceMonth.toString()
                                          : (property.priceNight > 0 
                                              ? property.priceNight.toString() 
                                              : (property.price != '0' && property.price != '0.0' && property.price.isNotEmpty ? property.price : 'Negotiable')),
                                    );
                                    return val;
                                  })(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18.2, // Slightly more prominent
                                    fontWeight: FontWeight.w900, // Stronger weight for premium feel
                                    color: AppTheme.brandColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                WidgetSpan(
                                  child: Transform.translate(
                                    offset: const Offset(
                                      1,
                                      -2.0,
                                    ), // Compensated offset
                                    child: Text(
                                      property.priceMonth > 0
                                          ? '/mo'
                                          : (property.priceNight > 0 ? '/night' : ''),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 2,
                    ), // Reverted to original gap above amenities
                    _buildAmenityItems(),
                    const SizedBox(
                      height: 5,
                    ), // Reduced from 7 to fix overflow
                    // Action Buttons
                    Row(
                      children: [
                        if (!isOwnerView) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                if (!AuthGuard.checkAuth(
                                  context,
                                  title: 'Visit Property',
                                  message: 'Log in to view complete details of this property.',
                                )) {
                                  return;
                                }
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
                                  vertical: 10.5,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.directions_walk_rounded,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Visit Now',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                if (!AuthGuard.checkAuth(
                                  context,
                                  title: 'Chat with Owner',
                                  message: 'Log in to direct message the property owner.',
                                )) {
                                  return;
                                }
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => chat_page.ChatScreen(
                                        ownerId: ownerId,
                                        name: ownerName,
                                        avatar: ownerAvatar,
                                        isVerified: isOwnerVerified,
                                        online: true,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.brandColor,
                                side: const BorderSide(
                                  color: AppTheme.brandColor,
                                  width: 1.0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(0, 1.0),
                                      child: SvgPicture.asset(
                                        'assets/icons/Message neww.svg',
                                        width: 16,
                                        height: 16,
                                        colorFilter: const ColorFilter.mode(
                                          AppTheme.brandColor,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Message',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
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
      'water_24_7': Icons.water_drop_outlined,
      'water_boring': Icons.waves_outlined,
      'water_melamchi': Icons.water_drop_outlined,
      'ac': Icons.ac_unit_outlined,
      'internet': Icons.wifi_outlined,
      'sunny_room': Icons.wb_sunny_outlined,
      'balcony': Icons.balcony_outlined,
      'kitchen': Icons.kitchen_outlined,
      'furnished': Icons.chair_outlined,
      'hot_water': Icons.hot_tub_outlined,
      'parking_bike': Icons.pedal_bike_outlined,
      'parking_car': Icons.directions_car_outlined,
      'security': Icons.security_outlined,
      'elevator': Icons.elevator_outlined,
      'power_backup': Icons.electric_bolt_outlined,
      'waste_mgmt': Icons.delete_outline,
      'peaceful': Icons.nature_people_outlined,
      'attached_bathroom': Icons.bathroom_outlined,
      // House Rules
      'family_only': Icons.family_restroom_outlined,
      'boys_allowed': Icons.man,
      'girls_allowed': Icons.woman,
      'pets_allowed': Icons.pets,
      'smoking_allowed': Icons.smoke_free,
      'alcohol_allowed': Icons.local_bar,
    };

    // 1. Build Location Widget
    Widget locationWidget = Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place_outlined,
            color: AppTheme.brandColor,
            size: 16,
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

    // 2. Build Amenities (Max 2 total items)
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
      if (count >= 2) break; // Maximum 2 items allowed
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
      case 'water_24_7':
      case 'water_melamchi':
        return 'Water';
      case 'water_boring':
        return 'Boring';
      case 'ac':
        return 'AC';
      case 'balcony':
        return 'Balcony';
      case 'furnished':
        return 'Furnished';
      case 'security':
        return 'Security';
      case 'elevator':
        return 'Elevator';
      case 'power_backup':
        return 'Power';
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
      case 'attached_bathroom':
        return 'Bath';
      case 'family_only':
        return 'Family';
      case 'boys_allowed':
        return 'Boys';
      case 'girls_allowed':
        return 'Girls';
      case 'pets_allowed':
        return 'Pets';
      case 'smoking_allowed':
        return 'Smoking';
      case 'alcohol_allowed':
        return 'Alcohol';
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
        child: Icon(Icons.image_outlined, color: Colors.grey[300], size: 40),
      ),
    );
  }
}
