import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
              "ID: ${p['id']}, Title: ${p['title']}, Price: ${p['price']}, Location: ${p['location']}",
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
    3. If NO properties in the list match the query, respond ONLY with: "No matching properties found. (अहिले उपलब्ध छैन)"
    4. Keep the response extremely concise.
    """;

    return _getAiResponse(
      prompt,
      systemPrompt:
          "You are a strict property matcher. You ONLY use provided data. You do NOT hallucinate.",
    );
  }

  /// 2. AI Scam Detector
  Future<String> detectScam(String title, String price, String area) async {
    String prompt = "Title: $title, Price: $price. Scam check for Nepal.";
    return _getAiResponse(prompt, systemPrompt: "Security expert.");
  }

  /// 3. AI Price Estimator
  Future<String> estimatePrice(String location, int rooms, String type) async {
    String prompt = "$rooms room $type in $location, Nepal. Estimate a fair monthly rent in NPR. Be concise. Reply in Nepali or English only.";
    return _getAiResponse(
      prompt,
      systemPrompt: "You are a real estate valuation expert in Nepal. You ONLY respond in Nepali or English. You NEVER use Hindi.",
    );
  }

  /// 4. AI Chatbot
  Future<String> getChatbotResponse(String message) async {
    const String systemPrompt = """
You are Khozna AI — the official bilingual assistant for Khozna, Nepal's premier room and property rental platform.

═══ LANGUAGE RULES (CRITICAL) ═══
- ALWAYS reply in BOTH Nepali (Devanagari) AND English.
- Format: Write the Nepali sentence first, then the English translation in parentheses or on the next line.
- Example: "हामीसँग किर्तिपुरमा कोठाहरू उपलब्ध छन्। (We have rooms available in Kirtipur.)"
- NEVER use Hindi. Not even a single Hindi word. If unsure between Nepali and Hindi, use English.

═══ PLATFORM RULES (CRITICAL) ═══
Khozna ONLY offers the following:
 • Rooms (कोठा)
 • Flats (फ्ल्याट)
 • Apartments (अपार्टमेन्ट)
 • Houses for Rent (घर भाडामा)
 • Property Listings in Nepal

If a user asks about ANYTHING outside this list (e.g., buying land, hotel booking, jobs, loans, cars, food, etc.), you MUST respond:
"माफ गर्नुहोस्, यो सुविधा अहिले Khozna मा उपलब्ध छैन। (Sorry, this feature is not available on Khozna right now.)"

═══ BEHAVIOR RULES ═══
- Be warm, friendly, and helpful.
- If a user asks "के कोठा पाइन्छ?" (Can I find a room?), enthusiastically help them narrow down by asking: location, budget, number of rooms.
- If a property type IS on Khozna, guide them to search or browse.
- Keep responses SHORT — maximum 4 sentences.
- Never hallucinate listings or make up prices.
""";
    return _getAiResponse(message, systemPrompt: systemPrompt);
  }

  /// 5. AI Description Generator
  Future<String> generateDescription({
    required String title,
    required String category,
    required String area,
    required String landmark,
    required List<String> amenities,
  }) async {
    final String prompt =
        """
    Generate a professional and catchy property description for a rental listing in Nepal.
    Details:
    - Title: $title
    - Category: $category
    - Location: $area, near $landmark
    - Amenities: ${amenities.join(', ')}
    
    The description should:
    1. Have a catchy opening line.
    2. Highlight the benefits of the location and nearby places (hospitals, schools, markets).
    3. Mention it's a great opportunity for tenants.
    4. Be around 3-4 sentences long.
    5. MUST be written ONLY in Nepali (Devanagari) or a natural Nepali/English mix. 
    6. ABSOLUTELY NO Hindi words. If you are unsure whether a word is Nepali or Hindi, write it in English instead.
    """;

    return _getAiResponse(
      prompt,
      systemPrompt:
          "You are a premium real estate marketing expert for Nepal. You write ONLY in Nepali (Devanagari script) or English. You NEVER use Hindi. If you accidentally think of a Hindi word, replace it with its English equivalent. This is a strict rule — violation means the output is rejected.",
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
          "You are a local neighborhood expert in Nepal who ONLY speaks Nepali and English. You know all major landmarks across Kathmandu, Lalitpur, Bhaktapur, and other major Nepali cities. You NEVER use Hindi — if unsure, use English instead.",
    );
  }

  /// 7. AI Auto-Location Entry (Reverse Geocoding + AI Extraction)
  Future<Map<String, String>> autoDetectLocationArea(double lat, double lng) async {
    try {
      // 1. Fetch raw address from OpenStreetMap (Free Nominatim API)
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng');
      final response = await http.get(url, headers: {'User-Agent': 'KhoznaApp/1.0'});
      
      if (response.statusCode != 200) {
        return {'area': '', 'landmark': ''};
      }
      
      final data = jsonDecode(response.body);
      final rawAddress = data['display_name'] ?? '';
      
      if (rawAddress.isEmpty) return {'area': '', 'landmark': ''};

      // 2. Ask AI to extract just Area and Landmark
      String prompt = '''
      Raw Address from GPS: $rawAddress
      
      Please extract the precise location and format the 'Area Name' as "Micro-Area, City" (e.g., 'Khasibazar, Kirtipur' or 'Baluwatar, Kathmandu'). Do not just provide the city name, always include the local neighborhood/village if available.
      Also provide a noticeable 'Landmark' (e.g. 'Near Nabil Bank', 'Close to Ring Road').
      Return ONLY a valid JSON object in this exact format with NO markdown formatting:
      {
        "area": "Local Area, City",
        "landmark": "landmark name"
      }
      ''';

      final aiResponse = await _getAiResponse(
        prompt,
        systemPrompt: "You are a precise JSON data extractor. Output ONLY raw valid JSON, no markdown, no explanation."
      );
      
      // Clean up potential markdown formatting that LLaMA might inject
      String cleanJson = aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsedJson = jsonDecode(cleanJson);
      
      return {
        'area': parsedJson['area']?.toString() ?? '',
        'landmark': parsedJson['landmark']?.toString() ?? ''
      };
    } catch (e) {
      print('Auto-detect location error: $e');
      return {'area': '', 'landmark': ''};
    }
  }
}
