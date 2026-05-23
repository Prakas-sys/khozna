import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorage {
  static const String _homeCacheKey = 'khozna_home_cache';
  static const String _profileCacheKey = 'khozna_profile_cache';
  static const String _lastLocationKey = 'khozna_last_location';

  /// Save the home section cache to persistent storage
  static Future<void> saveHomeCache(
    Map<int, List<Map<String, dynamic>>> cache,
  ) async {
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
            result[intKey] = value
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
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

  /// Save the user's profile data to persistent storage (for offline access)
  static Future<void> saveProfileCache(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileCacheKey, jsonEncode(profile));
    } catch (e) {
      print('Error saving profile cache: $e');
    }
  }

  /// Load the user's profile data from persistent storage
  static Future<Map<String, dynamic>?> loadProfileCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_profileCacheKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      print('Error loading profile cache: $e');
    }
    return null;
  }

  /// Clear the profile cache (e.g. on logout)
  static Future<void> clearProfileCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileCacheKey);
    } catch (e) {
      print('Error clearing profile cache: $e');
    }
  }

  /// Save the last known location name
  static Future<void> saveLastLocation(String location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLocationKey, location);
    } catch (e) {
      print('Error saving last location: $e');
    }
  }

  /// Load the last known location name
  static Future<String?> loadLastLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastLocationKey);
    } catch (e) {
      print('Error loading last location: $e');
    }
    return null;
  }

  static const String _lastActiveKey = 'khozna_last_active';

  /// Save the last active time (for 1 week login expiry)
  static Future<void> saveLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving last active time: $e');
    }
  }

  /// Load the last active time
  static Future<DateTime?> loadLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_lastActiveKey);
      if (timeStr != null) {
        return DateTime.parse(timeStr);
      }
    } catch (e) {
      print('Error loading last active time: $e');
    }
    return null;
  }
}
