import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:supabase_flutter/supabase_flutter.dart';

class KhoznaAiService {
  // Switched to GROQ for 100% Free, High-Speed Cloud AI in Nepal
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  final String apiKey;

  KhoznaAiService({String? apiKey})
    : apiKey = apiKey ?? dotenv.env['GROQ_API_KEY'] ?? '';

  /// Cloud AI Request with robust error handling
  Future<String> _getAiResponse(
    String prompt, {
    required String systemPrompt,
  }) async {
    // 1. Check if API Key is missing
    if (apiKey.isEmpty) {
      return "नमस्ते! (Hi!) 🇳🇵\nIt looks like the AI is not configured yet. Please follow these steps:\n1. Go to console.groq.com (It's 100% Free)\n2. Create an API Key\n3. Paste it in your .env file as GROQ_API_KEY";
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        return "Invalid API Key. Please check your Groq API key in the .env file.";
      } else {
        return "AI is busy at the moment. Please try again in a few seconds.";
      }
    } catch (e) {
      return "Connectivity issue. Please check your internet and try again.";
    }
  }

  /// 1. AI Property Matching
  Future<String> matchProperty(
    String userQuery,
    List<Map<String, dynamic>> properties,
  ) async {
    String propertyData = properties
        .map(
          (p) =>
              "ID: ${p['id']}, Title: ${p['title']}, Price: ${p['price']}, Location: ${p['area_name']}",
        )
        .join("\n");

    String prompt =
        """
    User Query: $userQuery
    Available Property List:
    $propertyData
    
    INSTRUCTIONS:
    1. Identify matching properties ONLY from the list above.
    2. Do NOT mention any locations or property types (like 'land') NOT in the list.
    3. If NO properties in the list match the query, respond ONLY with: "माफ गर्नुहोस्, कुनै मिल्दो प्रोपर्टी भेटिएन। (No matching properties found.)"
    4. RESPONSE FORMAT: Strictly Nepali (Devanagari) followed by English in parentheses.
    5. Keep the response extremely concise.
    """;

    return _getAiResponse(
      prompt,
      systemPrompt:
          "You are a strict property matcher. You ONLY use provided data. You do NOT hallucinate.",
    );
  }

  /// 2. AI Scam Detector
  Future<String> detectScam(String title, String price, String area) async {
    String prompt =
        "Title: $title, Price: $price. Scam check for Nepal. Tell me if it looks suspicious.";
    return _getAiResponse(
      prompt,
      systemPrompt:
          "Security expert. Answer ONLY in Nepali followed by English in parentheses. NO HINDI.",
    );
  }

  /// 3. AI Price Estimator
  Future<String> estimatePrice(String location, int rooms, String type) async {
    String prompt =
        "$rooms room $type in $location, Nepal. Estimate a fair monthly rent in NPR. Be concise.";
    return _getAiResponse(
      prompt,
      systemPrompt:
          "You are a real estate valuation expert in Nepal. Answer ONLY in Nepali followed by English in parentheses. ABSOLUTELY NO HINDI. Use 'कोठा' (Kotha), never use 'कमरा' (Kamara).",
    );
  }

  /// 4. AI Chatbot
  Future<Map<String, dynamic>> getChatbotResponse(String message) async {
    // 1. Fetch live context from the database
    String liveContext = "Currently, there are no active listings on Khozna.";
    List<dynamic> foundProperties = [];
    try {
      // We try to find properties matching words in the message
      // and also include some general available properties
      final List<String> keywords = message
          .split(' ')
          .where((w) => w.length > 2)
          .toList();

      var query = Supabase.instance.client
          .from('properties')
          .select('title, category, area_name, price, bedrooms')
          .eq('status', 'available');

      if (keywords.isNotEmpty) {
        String filter = keywords
            .map((k) => "area_name.ilike.%$k%,title.ilike.%$k%")
            .join(',');
        query = query.or(filter);
      }

      final response = await query.limit(15);

      if ((response as List).isNotEmpty) {
        foundProperties = response;
        liveContext =
            "Here is the CURRENT LIVE INVENTORY on Khozna relevant to the query. Use this exact data to answer the user:\n";
        for (var p in response) {
          liveContext +=
              "- ${p['category']} in ${p['area_name']} for ₹ ${p['price']}/mo (${p['bedrooms'] ?? 1} bedrooms). Title: ${p['title']}\n";
        }
      } else {
        // Fallback: fetch most recent available if no keyword match
        final fallback = await Supabase.instance.client
            .from('properties')
            .select('title, category, area_name, price, bedrooms')
            .eq('status', 'available')
            .order('created_at', ascending: false)
            .limit(5);

        if ((fallback as List).isNotEmpty) {
          liveContext =
              "No direct match found for the specific query, but here are some overall available properties on Khozna:\n";
          for (var p in fallback) {
            liveContext +=
                "- ${p['category']} in ${p['area_name']} for ₹ ${p['price']}/mo. Title: ${p['title']}\n";
          }
        }
      }
    } catch (e) {
      print('Error fetching AI context: $e');
    }

    final String systemPrompt =
        """
You are Khozna AI — the official assistant for Khozna, Nepal's premier property rental platform.

CRITICAL LANGUAGE RULE: 
You MUST use ONLY Pure Nepali (Devanagari) and English. 
You are STRICTLY FORBIDDEN from using ANY Hindi words, grammar, or sentence structures.

REAL DATABASE CONTEXT (GROUND TRUTH):
$liveContext

BEHAVIOR RULES:
1. If the user asks for a property (room, flat, apartment) in a specific location:
   - Check the REAL DATABASE CONTEXT above.
   - If a match exists, provide details (Price, Location, Title).
   - If NO match exists in the context, say: "माफ गर्नुहोस्, अहिले तपाईंले खोज्नुभएको ठाउँमा कोठा उपलब्ध छैन। (Sorry, we don't have a match for your request in our database right now.)"
2. If the user is just greeting or asking general questions about Khozna:
   - Answer warmly and explain that Khozna helps people find rooms and flats in Nepal easily.
3. ABSOLUTELY NO HALLUCINATION. Do NOT invent properties that are not in the context.
4. Keep responses SHORT and DIRECT (maximum 3 sentences).
5. Format: Nepali sentence followed by English in parentheses.
""";
    final aiText = await _getAiResponse(message, systemPrompt: systemPrompt);
    return {'text': aiText, 'properties': foundProperties};
  }

  Future<String> generateDescription({
    required String title,
    required String category,
    required String area,
    required String landmark,
    required String price,
    required String priceNight,
    required String bedrooms,
    required String bathrooms,
    required String floor,
    required String sqft,
    required bool isNegotiable,
    required List<String> amenities,
  }) async {
    final String prompt =
        """
    Generate a professional and catchy property description for a rental listing in Nepal.
    
    PROPERTY DATA:
    - Title: $title
    - Category: $category
    - Location Area: $area
    - Specific Landmark: $landmark
    - Monthly Rent: ₹ $price (Negotiable: ${isNegotiable ? 'Yes' : 'No'})
    - Daily Rent (if applicable): ${priceNight.isNotEmpty ? '₹ $priceNight' : 'N/A'}
    - Features: ${bedrooms.isNotEmpty ? '$bedrooms Bedrooms' : ''}, ${bathrooms.isNotEmpty ? '$bathrooms Bathrooms' : ''}, Floor: $floor, Size: $sqft sq.ft
    - Amenities & Rules: ${amenities.join(', ')}
    
    INSTRUCTIONS:
    1. WRITING STYLE: Use a mix of Professional and Catchy marketing tone.
    2. LOCATION & LANDMARKS: You MUST emphasize the location ($area) and the nearby landmark ($landmark). Mention why this location is convenient (e.g., transport, safety, neighborhood vibe).
    3. PRICE & VALUE: Mention the rent clearly and highlight if it's a good deal for the features provided.
    4. RENTAL ONLY: This is for a RENTAL listing. ABSOLUTELY FORBIDDEN to mention "Selling", "Buying", or "For Sale". Use terms like "Rent" (भाडा) only.
    5. UNIT TYPE: Use specific terms like "कोठा" (Room) or "फ्ल्याट" (Flat) based on the category. Avoid calling it a "घर" (House) unless it's a whole house for rent.
    6. LANGUAGE (STRICT): Use ONLY English and Pure Nepali (Devanagari). 
    7. NO HINDI: Strictly forbidden from using Hindi words like 'कमरा' (use 'कोठा'), 'मकान', 'बिस्तार' (use 'विवरण'). If a word feels like Hindi, use the English term instead.
    8. LENGTH: 4-6 concise sentences.
    9. CURRENCY: Always use ₹ symbol.
    """;

    return _getAiResponse(
      prompt,
      systemPrompt:
          "You are a premium real estate copywriter in Nepal. You write descriptions that sell. You use a natural blend of Nepali and English. You have a zero-tolerance policy for Hindi words. You always focus on the convenience of the location and landmarks provided.",
    );
  }

  /// 5.1 AI Video Caption Generator (For Reels)
  Future<String> generateVideoCaption({
    required String category,
    required String area,
    required String landmark,
    required String price,
  }) async {
    final String prompt = """
    Generate a short, viral-style video caption for a property reel in Nepal.
    Details:
    - Type: $category
    - Location: $area, near $landmark
    - Price: ₹ $price
    
    The caption should:
    1. Be very short (1-2 sentences).
    2. Use high-energy emojis (e.g., 🏠, ✨, 📍).
    3. Include a call to action (e.g., "DM for visit", "Don't miss out!").
    4. LANGUAGE: Use a natural mix of English and Nepali (Devanagari or Romanized).
    5. NO HINDI: Strictly forbidden from using any Hindi words.
    6. Mention the price clearly with ₹ symbol.
    """;

    return _getAiResponse(
      prompt,
      systemPrompt: "You are a viral social media manager for a real estate app in Nepal. You write punchy, high-engagement captions. You ONLY use English and Nepali. NO HINDI allowed.",
    );
  }

  /// 6. AI Location Expert (Verify & Nearby Analysis)
  Future<String> verifyLocation(String area, String landmark) async {
    String prompt =
        """
    Location Area: $area
    Nearby Landmark: $landmark
    
    Please analyze this location in Nepal. 
    1. Confirm if this is a known area/tole in Nepal.
    2. List 3-4 important nearby places (Major Hospitals, Schools, or Markets) that are usually near this area.
    3. Give a short 'Vibe Check' of the neighborhood (e.g., 'Residential', 'Commercial', 'Quiet').
    
    LANGUAGE RULE: Write ONLY in Nepali (Devanagari) or English. NO Hindi words at all.
    Keep the response concise and friendly for a rental app user.
    """;

    return _getAiResponse(
      prompt,
      systemPrompt:
          "You are a local neighborhood expert in Nepal who ONLY speaks Pure Nepali and English. You know all major landmarks across Nepali cities. You NEVER use Hindi. Use 'कोठा' (Kotha) not 'कमरा' (Kamara). If unsure of a Nepali term, write it in English.",
    );
  }

  Future<Map<String, String>> autoDetectLocationArea(
    double lat,
    double lng,
  ) async {
    try {
      String micro = '';
      String city = '';
      String road = '';

      // 1. Google Native Geocoding
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          lat,
          lng,
        );
        if (placemarks.isNotEmpty) {
          geo.Placemark place = placemarks.first;
          road = place.street ?? place.thoroughfare ?? '';
          String name = place.name ?? '';
          String subLocality = place.subLocality ?? '';
          city = place.locality ?? place.subAdministrativeArea ?? 'Nepal';

          if (road.isNotEmpty && !road.contains('+') && road.length > 3) {
            micro = road;
          } else if (name.isNotEmpty && !name.contains('+')) {
            micro = name;
          } else {
            micro = subLocality;
          }
          micro = micro.replaceAll('Road', '').replaceAll('Street', '').trim();
          if (micro.endsWith(',')) micro = micro.substring(0, micro.length - 1);
        }
      } catch (_) {}

      // 2. OSM Fallback if Google misses deep micro Area
      if (micro.isEmpty || micro.toLowerCase() == city.toLowerCase()) {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
        );
        final response = await http.get(
          url,
          headers: {'User-Agent': 'KhoznaApp/1.0'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final displayName = data['display_name']?.toString() ?? '';
          if (displayName.isNotEmpty) {
            List<String> parts = displayName
                .split(',')
                .map((e) => e.trim())
                .toList();
            if (parts.isNotEmpty) {
              micro = parts[0];
              if (parts.length > 1 && city.isEmpty) city = parts[1];
            }
          }
        }
      }

      // 3. Assemble and Clean
      String cleanText(String input) {
        // Skip Plus Codes like "H9Q2+X4"
        if (input.contains('+') && input.length < 12) return '';
        // Skip purely numeric codes/house numbers (like "42" or "101")
        if (RegExp(r'^\d*[a-zA-Z]?$').hasMatch(input.replaceAll(' ', '')))
          return '';
        return input;
      }

      String area = '';
      micro = cleanText(micro);
      city = cleanText(city);
      road = cleanText(road);

      if (micro.isNotEmpty &&
          city.isNotEmpty &&
          micro.toLowerCase() != city.toLowerCase()) {
        if (micro.toLowerCase().contains(city.toLowerCase())) {
          area = micro;
        } else {
          area = '$micro, $city';
        }
      } else if (city.isNotEmpty) {
        area = city;
      } else {
        area = micro;
      }

      String landmark = '';
      if (road.isNotEmpty && road != micro && cleanText(road).isNotEmpty) {
        landmark = 'Near ${cleanText(road)}';
      } else if (micro.isNotEmpty &&
          micro.toLowerCase() != city.toLowerCase()) {
        // If there's no road, the 'micro' location (often a shop, school, or neighborhood)
        // should become the specific landmark, and we keep the broader city as the area!
        landmark = 'Near $micro';
        area = city.isNotEmpty ? city : area;
      }

      return {'area': area, 'landmark': landmark};
    } catch (e) {
      print('Auto-detect location error: $e');
      return {'area': '', 'landmark': ''};
    }
  }

  /// 7. AI Nearby Landmarks Generator
  Future<List<Map<String, dynamic>>> getNearbyLandmarks(
    String area,
    String landmark,
  ) async {
    final String prompt =
        """
    Location: $area, near $landmark
    Please identify 3-4 real or highly probable nearby landmarks for this location in Nepal (KTM, Lalitpur, Bhaktapur, etc).
    Return ONLY a JSON list of objects.
    
    Keys required:
    - name: (The name of the place in English)
    - distance: (A realistic distance in meters between 50m and 300m, e.g., "120m")
    - type: (The category, e.g., 'Health', 'Market', 'School', 'Bank', 'Transport')
    - icon_code: (A Flutter IconData name suffix, e.g., 'local_hospital_rounded', 'shopping_bag_rounded', 'school_rounded', 'account_balance_rounded', 'directions_bus_rounded')
    
    Example Output:
    [{"name": "Civil Bank ATM", "distance": "80m", "type": "Bank", "icon_code": "account_balance_rounded"}]
    """;

    final String response = await _getAiResponse(
      prompt,
      systemPrompt:
          "You are a local geography expert for Nepal. You return ONLY clean JSON. No preamble, no explanation.",
    );

    try {
      String jsonPart = response;
      if (response.contains('[')) {
        jsonPart = response.substring(
          response.indexOf('['),
          response.lastIndexOf(']') + 1,
        );
      }
      final List<dynamic> decoded = jsonDecode(jsonPart);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('AI Nearby Landmark error: $e');
      return [];
    }
  }

  /// 8. AI Location Refinement (Fixes incorrect/broad map names)
  Future<String> refineLocationWithAI({
    required double lat,
    required double lng,
    required String rawAddress,
  }) async {
    final String prompt =
        """
    Coordinates: $lat, $lng
    Raw Map Data: $rawAddress
    
    CONTEXT:
    This user is in Nepal. Standard Map APIs often return broad names. Your job is to find the precise "Neighborhood, City".
    
    IMPORTANT:
    If "Native Specific" is provided (e.g., "Khasibazar"), TRUST IT. That is the exact Tole/Neighborhood from the user's phone GPS. Do NOT change it to a nearby area like "Tyanglaphat" unless "Native Specific" is empty or a house number.
    
    NEIGHBORHOOD GUIDE for Kirtipur:
    - If near 27.67, 85.27: It is usually "Khasibazar".
    - If near 27.68, 85.28: It is usually "Tyanglaphat".
    - "Panga", "Naya Bazaar", "Chobhar" are also common.
    
    TASK:
    Return exactly as "Neighborhood, City".
    1. AVOID REDUNDANCY: No "Kirtipur, Kirtipur".
    2. BE REAL: Use the actual street-level name if provided in raw data.
    
    EXAMPLES:
    - "Khasibazar, Kirtipur"
    - "Jhamsikhel, Lalitpur"
    
    Return ONLY the polished "Neighborhood, City" string. NO EXPLANATION.
    """;

    final response = await _getAiResponse(
      prompt,
      systemPrompt:
          "You are a Nepali geography expert. You always prioritize the 'Native Specific' neighborhood name provided in the input over generic city names. You never confuse Khasibazar with Tyanglaphat.",
    );

    // Clean up any quotes or extra whitespace the AI might return
    return response.replaceAll('"', '').replaceAll("'", "").trim();
  }
}
