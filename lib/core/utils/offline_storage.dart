import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorage {
  static const String _homeCacheKey = 'khozna_home_cache';
  
  /// Save the home section cache to persistent storage
  static Future<void> saveHomeCache(Map<int, List<Map<String, dynamic>>> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert map keys to string since JSON requires string keys
      final Map<String, dynamic> serializableCache = {};
      cache.forEach((key, value) {
        serializableCache[key.toString()] = value;
      });
      
      final String jsonString = jsonEncode(serializableCache);
      await prefs.setString(_homeCacheKey, jsonString);
    } catch (e) {
      // Fail silently for cache operations to not disrupt user experience
      print('Error saving home cache: $e');
    }
  }

  /// Load the home section cache from persistent storage
  static Future<Map<int, List<Map<String, dynamic>>>> loadHomeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_homeCacheKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
        final Map<int, List<Map<String, dynamic>>> result = {};
        
        decodedMap.forEach((key, value) {
          final intKey = int.tryParse(key);
          if (intKey != null && value is List) {
            // Ensure deep casting to Map<String, dynamic>
            result[intKey] = value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        });
        
        return result;
      }
    } catch (e) {
      print('Error loading home cache: $e');
    }
    return {};
  }
  /// Clear the home section cache
  static Future<void> clearHomeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_homeCacheKey);
    } catch (e) {
      print('Error clearing home cache: $e');
    }
  }
}
