class Property {
  final String id;
  final String title;
  final String description;
  final String price;
  final String location;
  final String areaName;
  final List<String> images;
  final String category;
  final int bedrooms;
  final int bathrooms;
  final String area;
  final String floor;
  final String status;
  final String ownerId;
  final String ownerName;
  final String ownerAvatar;
  final bool isOwnerVerified;
  final List<String> amenities;
  final List<String> houseRules;
  final double? latitude;
  final double? longitude;
  final String landmark;
  final List<String> nearbyLandmarks;
  final bool isStudentFriendly;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.areaName,
    required this.images,
    required this.category,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.floor,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    required this.ownerAvatar,
    required this.isOwnerVerified,
    required this.amenities,
    required this.houseRules,
    this.latitude,
    this.longitude,
    this.landmark = '',
    this.nearbyLandmarks = const [],
    this.isStudentFriendly = false,
  });

  /// First image URL, or a sensible fallback placeholder.
  String get imageUrl => images.isNotEmpty
      ? images.first
      : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';

  factory Property.fromMap(Map<String, dynamic> map) {
    final List joinImages = map['property_images'] ?? [];
    final List arrayImages = map['images'] ?? [];
    List<String> finalImages = [];

    if (joinImages.isNotEmpty) {
      finalImages = joinImages.map((i) => i['image_url'].toString()).toList();
    } else if (arrayImages.isNotEmpty) {
      finalImages = arrayImages.map((i) => i.toString()).toList();
    }

    final ownerProfile = map['profiles'] as Map<String, dynamic>?;

    return Property(
      id: map['id'].toString(),
      title: map['title'] ?? 'Apartment',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toString(),
      location: map['area_name'] ?? 'Kathmandu',
      areaName: map['area_name'] ?? 'Kathmandu',
      images: finalImages,
      category: map['category'] ?? 'Room',
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      area: (map['sq_ft'] ?? 0).toString(),
      floor: map['floor'] ?? 'N/A',
      status: map['status'] ?? 'available',
      ownerId: map['owner_id'] ?? '',
      ownerName: ownerProfile?['full_name'] ?? 'Khozna User',
      ownerAvatar: ownerProfile?['avatar_url'] ?? '',
      isOwnerVerified: ownerProfile?['kyc_status'] == 'verified',
      amenities: (map['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      houseRules: (map['house_rules'] as List?)?.map((e) => e.toString()).toList() ?? [],
      latitude: map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null,
      landmark: map['landmark']?.toString() ?? '',
      nearbyLandmarks: (map['nearby_landmarks'] as List?)?.map((l) {
        if (l is Map) return l['name']?.toString() ?? '';
        return l.toString();
      }).toList() ?? [],
      isStudentFriendly: map['is_student_friendly'] ?? false,
    );
  }
}
