import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/core/services/khozna_ai_service.dart';
import 'package:khozna/core/security/security_utils.dart';
import 'package:khozna/core/services/upload_manager.dart';
import 'dart:io';

class PropertyRepository {
  static final _client = Supabase.instance.client;

  /// Fetch properties for a specific section (Near You, Student, etc.)
  static Future<List<Property>> getSectionProperties({
    required int index,
    double? lat,
    double? lng,
    List<String> excludeIds = const [],
  }) async {
    try {
      dynamic query = _client
          .from('properties')
          .select(
            '*, property_images(image_url), profiles:owner_id(full_name, avatar_url, kyc_status, area_name)',
          );

      if (index != 5) {
        query = query.eq('status', 'available');
      }

      if (excludeIds.isNotEmpty) {
        query = query.not('id', 'in', '(${excludeIds.join(",")})');
      }

      switch (index) {
        case 0: // Near You
          if (lat != null && lng != null) {
            query = query
                .gte('latitude', lat - 0.1)
                .lte('latitude', lat + 0.1)
                .gte('longitude', lng - 0.1)
                .lte('longitude', lng + 0.1);
          }
          break;
        case 1: // Special Offers / Hot Deals
          query = query.or(
            'description.ilike.%offer%,description.ilike.%discount%,title.ilike.%offer%,is_negotiable.eq.true',
          );
          break;
        case 2: // Student Housing
          query = query.eq('is_student_friendly', true).lt('price', 9000);
          break;
        case 3: // Family Flats
          query = query.eq('category', 'Flat');
          break;
        case 4: // Premium
          query = query.or('is_premium.eq.true,price.gt.20000');
          break;
        case 5: // Booked Section (Auto-deletes in 6 days)
          query = query.eq('status', 'booked');
          break;
      }

      final data = await query
          .order('status', ascending: true)
          .order('created_at', ascending: false)
          .limit(6);

      final List<Map<String, dynamic>> rawData =
          List<Map<String, dynamic>>.from(data);

      if (rawData.isNotEmpty) {
        final currentCache = Map<int, List<Map<String, dynamic>>>.from(
          homeSectionCache.value,
        );
        currentCache[index] = rawData;
        homeSectionCache.value = currentCache;
        OfflineStorage.saveHomeCache(currentCache);
      }

      return rawData.map((e) => Property.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching section $index: $e');
      final cached = homeSectionCache.value[index] ?? [];
      return cached.map((e) => Property.fromMap(e)).toList();
    }
  }

  /// Initial Load for Master Memory: Fetch all IDs the user has saved.
  static Future<void> fetchSavedPropertyIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('saved_properties')
          .select('property_id')
          .eq('user_id', user.id);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );
      final set = data.map((e) => e['property_id'].toString()).toSet();
      savedPropertiesStore.value = set;
    } catch (e) {
      debugPrint('Error fetching saved IDs: $e');
    }
  }

  /// Toggle saving a property
  static Future<void> toggleSaveProperty(String propertyId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final current = Set<String>.from(savedPropertiesStore.value);
    final isCurrentlySaved = current.contains(propertyId);

    if (isCurrentlySaved) {
      current.remove(propertyId);
    } else {
      current.add(propertyId);
    }
    savedPropertiesStore.value = current;

    try {
      if (isCurrentlySaved) {
        await _client
            .from('saved_properties')
            .delete()
            .eq('user_id', user.id)
            .eq('property_id', propertyId);
      } else {
        await _client.from('saved_properties').insert({
          'user_id': user.id,
          'property_id': propertyId,
        });
      }
    } catch (e) {
      debugPrint('Database Error: $e');
      // Revert if failed
      final reverted = Set<String>.from(savedPropertiesStore.value);
      isCurrentlySaved ? reverted.add(propertyId) : reverted.remove(propertyId);
      savedPropertiesStore.value = reverted;
    }
  }

  /// Fetch all saved properties
  static Future<List<Property>> getSavedProperties() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await _client
          .from('saved_properties')
          .select(
            '*, properties(*, property_images(*), profiles(full_name, avatar_url, kyc_status, area_name))',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => Property.fromMap(e['properties']))
          .toList();
    } catch (e) {
      debugPrint('Error fetching saved properties: $e');
      return [];
    }
  }

  /// Admin: Fetch all properties for moderation
  static Future<List<Property>> getAllPropertiesForAdmin() async {
    try {
      final response = await _client
          .from('properties')
          .select(
            '*, property_images(*), profiles(full_name, avatar_url, kyc_status, area_name)',
          )
          .order('created_at', ascending: false);
      return (response as List).map((e) => Property.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching properties for admin: $e');
      return [];
    }
  }

  static Future<void> updatePropertyStatus(String id, String status) async {
    await _client.from('properties').update({'status': status}).eq('id', id);
  }

  static Future<void> deletePropertyPermanently(String id) async {
    await _client.from('property_images').delete().eq('property_id', id);
    await _client.from('properties').delete().eq('id', id);
  }

  /// Create a new property listing with AI checks and media uploads
  static Future<String> createProperty({
    required String title,
    required String category,
    required String areaName,
    required String landmark,
    required double price,
    required int bedrooms,
    required int bathrooms,
    required int guests,
    required String floor,
    required String sqFt,
    required bool isNegotiable,
    required List<String> amenities,
    required List<String> houseRules,
    required List<File> images,
    required String description,
    double? latitude,
    double? longitude,
    File? videoFile,
    List<String>? preUploadedImageUrls,
    String? preUploadedVideoUrl,
    double priceNight = 0,
    double priceMonth = 0,
    String? videoCaption,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // 1. Sanitization (Defense Layer)
    final cleanTitle = SecurityUtils.sanitizeInput(title);
    final cleanArea = SecurityUtils.sanitizeInput(areaName);
    final cleanLandmark = SecurityUtils.sanitizeInput(landmark);
    final cleanDescription = SecurityUtils.sanitizeInput(
      description,
      maxLength: 1000,
    );
    final cleanVideoCaption = videoCaption != null 
        ? SecurityUtils.sanitizeInput(videoCaption, maxLength: 500) 
        : null;

    // 2. AI Scam Check (Fire and forget, non-blocking)
    final aiService = KhoznaAiService();
    aiService
        .detectScam(cleanTitle, price.toString(), cleanArea)
        .then((scamResult) {
          if (scamResult.toLowerCase().contains('scam')) {
            debugPrint('AI SCAM WARNING: $scamResult');
          }
        })
        .catchError((e) => debugPrint('AI Scam Check Error: $e'));

    // 3. Concurrent Media Uploads & AI Landmark Detection
    // Filter out images that are already pre-uploaded
    final List<File> imagesToUpload = [];
    final List<String> finalImageUrls = preUploadedImageUrls ?? [];
    
    if (preUploadedImageUrls == null || preUploadedImageUrls.length < images.length) {
      // Find which ones need uploading
      // For simplicity, if preUploadedImageUrls is provided, we assume they match the first N images
      // A better way is to check the path, but preUploadedImageUrls are just strings.
      // So let's re-verify or just upload the missing ones.
      // In our current AddPropertyScreen logic, we pass ALREADY UPLOADED ones.
      
      for (var file in images) {
        // If we don't have this file's URL in our pre-uploaded list, add to upload queue
        // (This is a bit tricky without path mapping in repository, 
        // but UploadManager.instance.getUrl(file.path) can be used here too)
        final url = CloudinaryService.uploadImage(file);
        imagesToUpload.add(file);
      }
    }

    Future<String?> videoUploadFuture = (videoFile != null && preUploadedVideoUrl == null)
        ? CloudinaryService.uploadVideo(videoFile)
        : Future.value(preUploadedVideoUrl);

    // We only upload images that weren't captured by the background uploader
    // Actually, to keep it simple and robust:
    Future<List<String?>> imagesUploadFuture = Future.wait(
      images.map((file) {
        final existingUrl = preUploadedImageUrls?.firstWhere(
          (url) => false, // We can't easily match URL to File here without path context
          orElse: () => '',
        );
        // Let's use UploadManager here too for consistency
        final managerUrl = UploadManager.instance.getUrl(file.path);
        if (managerUrl != null) return Future.value(managerUrl);
        return CloudinaryService.uploadImage(file);
      }),
    );

    Future<List<Map<String, dynamic>>> landmarksFuture = aiService
        .getNearbyLandmarks(cleanArea, cleanLandmark)
        .catchError((e) {
          debugPrint('AI Landmarks Error: $e');
          return <Map<String, dynamic>>[];
        });

    final results = await Future.wait([
      videoUploadFuture,
      imagesUploadFuture,
      landmarksFuture,
    ]);

    final String? videoUrl = results[0] as String?;
    final List<String?> uploadResults = results[1] as List<String?>;
    final List<Map<String, dynamic>> nearbyLandmarks =
        results[2] as List<Map<String, dynamic>>;

    final List<String> uploadedUrls = uploadResults
        .whereType<String>()
        .toList();

    if (uploadedUrls.isEmpty) throw 'Failed to upload any images.';

    // 5. Algorithm: Auto-categorize based on keywords
    final studentKeywords = [
      'student',
      'college',
      'university',
      'tuition',
      'hostel',
      'p.g.',
      'pg',
      'library',
      'campus',
      'विद्यार्थी',
      'कलेज',
      'अध्ययन',
    ];
    final premiumKeywords = [
      'premium',
      'luxury',
      'modern',
      'deluxe',
      'fully furnished',
      'modular',
      'brand new',
      'विलासी',
      'आधुनिक',
      'भिआइपी',
      'vip',
    ];

    final fullText = (cleanTitle + cleanDescription).toLowerCase();
    final bool autoStudent = studentKeywords.any((k) => fullText.contains(k));
    final bool autoPremium =
        premiumKeywords.any((k) => fullText.contains(k)) || price >= 18000;

    // 6. Database Insert
    final response = await _client
        .from('properties')
        .insert({
          'owner_id': user.id,
          'title': cleanTitle,
          'category': category,
          'area_name': cleanArea,
          'landmark': cleanLandmark,
          'price': price,
          'bedrooms': bedrooms,
          'bathrooms': bathrooms,
          'guests': guests,
          'floor': floor,
          'sq_ft': sqFt,
          'is_negotiable': isNegotiable,
          'amenities': amenities,
          'house_rules': houseRules,
          'images': uploadedUrls,
          'description': cleanDescription,
          'latitude': latitude,
          'longitude': longitude,
          'video_url': videoUrl,
          'video_caption': cleanVideoCaption,
          'status': 'available',
          'is_verified': true,
          'nearby_landmarks': nearbyLandmarks,
          'is_premium': autoPremium,
          'is_student_friendly': autoStudent,
          'price_night': priceNight,
          'price_month': priceMonth > 0 ? priceMonth : price,
        })
        .select('id')
        .single();

    final String propertyId = response['id'];

    // 5. Insert Image Records
    final List<Map<String, dynamic>> imageData = uploadedUrls
        .map((url) => {'property_id': propertyId, 'image_url': url})
        .toList();
    await _client.from('property_images').insert(imageData);

    // 6. Update User Role
    await _client.from('profiles').update({'is_owner': true}).eq('id', user.id);

    // 7. Trigger Global Refresh
    refreshTrigger.value++;

    return propertyId;
  }
}
