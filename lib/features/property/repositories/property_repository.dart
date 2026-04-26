import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/core/services/khozna_ai_service.dart';
import 'dart:io';

class PropertyRepository {
  static final _client = Supabase.instance.client;

  /// Fetch properties for a specific section (Near You, Student, etc.)
  static Future<List<Property>> getSectionProperties({
    required int index,
    double? lat,
    double? lng,
  }) async {
    try {
      dynamic query = _client
          .from('properties')
          .select('*, property_images(image_url), profiles:owner_id(full_name, avatar_url, kyc_status)');

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
        case 2: // Student Housing
          query = query.eq('category', 'Room').lt('price', 7000);
          break;
        case 3: // Family Flats
          query = query.eq('category', 'Flat');
          break;
        case 4: // Premium
          query = query.or('is_premium.eq.true,price.gt.20000');
          break;
      }

      final data = await query
          .order('status', ascending: true)
          .order('created_at', ascending: false)
          .limit(6);

      final List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(data);
      
      if (rawData.isNotEmpty) {
        final currentCache = Map<int, List<Map<String, dynamic>>>.from(homeSectionCache.value);
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

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
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
        await _client.from('saved_properties').delete().eq('user_id', user.id).eq('property_id', propertyId);
      } else {
        await _client.from('saved_properties').insert({'user_id': user.id, 'property_id': propertyId});
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
          .select('*, properties(*, property_images(*), profiles(full_name, avatar_url, kyc_status))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Property.fromMap(e['properties'])).toList();
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
          .select('*, property_images(*), profiles(full_name, avatar_url, kyc_status)')
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
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // 1. AI Scam Check
    final aiService = KhoznaAiService();
    try {
      final scamResult = await aiService.detectScam(title, price.toString(), areaName);
      if (scamResult.toLowerCase().contains("scam")) {
        debugPrint("AI SCAM WARNING: $scamResult");
      }
    } catch (e) {
      debugPrint("AI Scam Check Error: $e");
    }

    // 2. Parallel Media Uploads
    String? videoUrl;
    if (videoFile != null) {
      videoUrl = await CloudinaryService.uploadVideo(videoFile);
    }

    final List<Future<String?>> uploadFutures = images.map((file) => CloudinaryService.uploadImage(file)).toList();
    final List<String?> uploadResults = await Future.wait(uploadFutures);
    final List<String> uploadedUrls = uploadResults.whereType<String>().toList();

    if (uploadedUrls.isEmpty) throw 'Failed to upload any images.';

    // 3. AI Landmark Detection
    List<Map<String, dynamic>> nearbyLandmarks = [];
    try {
      nearbyLandmarks = await aiService.getNearbyLandmarks(areaName, landmark);
    } catch (e) {
      debugPrint("AI Landmarks Error: $e");
    }

    // 4. Database Insert
    final response = await _client.from('properties').insert({
      'owner_id': user.id,
      'title': title,
      'category': category,
      'area_name': areaName,
      'landmark': landmark,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'floor': floor,
      'sq_ft': sqFt,
      'is_negotiable': isNegotiable,
      'amenities': amenities,
      'house_rules': houseRules,
      'images': uploadedUrls,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'video_url': videoUrl,
      'status': 'available',
      'is_verified': true,
      'nearby_landmarks': nearbyLandmarks,
      'is_premium': price >= 15000.0,
    }).select('id').single();

    final String propertyId = response['id'];

    // 5. Insert Image Records
    final List<Map<String, dynamic>> imageData = uploadedUrls.map((url) => {
      'property_id': propertyId,
      'image_url': url,
    }).toList();
    await _client.from('property_images').insert(imageData);

    // 6. Update User Role
    await _client.from('profiles').update({'is_owner': true}).eq('id', user.id);

    return propertyId;
  }
}
