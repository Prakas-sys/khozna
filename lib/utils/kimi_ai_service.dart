import 'dart:convert';
import 'package:http/http.dart' as http;

class KimiAiService {
  // Switched to OpenRouter for 100% Forever Free Cloud AI
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  final String apiKey = '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';

  KimiAiService({String? apiKey}); // Key is now hardcoded for stability

  /// 100% FREE Cloud AI Request (via OpenRouter Free Models)
  Future<String> _getAiResponse(String prompt, {required String systemPrompt}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://khozna.com', // Required by OpenRouter
          'X-Title': 'Khozna App',
        },
        body: jsonEncode({
          // Using the 100% FREE Gemma 3 12B model (confirmed by user screenshot)
          'model': 'google/gemma-3-12b-it:free', 
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }

  /// 1. AI Property Matching
  Future<String> matchProperty(String userQuery, List<Map<String, dynamic>> properties) async {
    String propertyData = properties.map((p) => 
      "ID: ${p['id']}, Title: ${p['title']}, Price: ${p['price']}, Location: ${p['location']}"
    ).join("\n");

    String prompt = "User Query: $userQuery\nData:\n$propertyData\nFind matches.";
    return _getAiResponse(prompt, systemPrompt: "Property expert for Nepal.");
  }

  /// 2. AI Scam Detector
  Future<String> detectScam(String title, String price, String area) async {
    String prompt = "Title: $title, Price: $price. Scam check for Nepal.";
    return _getAiResponse(prompt, systemPrompt: "Security expert.");
  }

  /// 3. AI Price Estimator
  Future<String> estimatePrice(String location, int rooms, String type) async {
    String prompt = "$rooms room $type in $location. Price estimation?";
    return _getAiResponse(prompt, systemPrompt: "Valuation expert.");
  }

  /// 4. AI Chatbot
  /// 5. AI Location Expert (Verify & Nearby Analysis)
  Future<String> verifyLocation(String area, String landmark) async {
    String prompt = """
    Location Area: $area
    Nearby Landmark: $landmark
    
    Please analyze this location in Nepal. 
    1. Confirm if this is a known area/tink in Nepal.
    2. List 3-4 important nearby places (Major Hospitals, Schools, or Markets) that are usually near this area.
    3. Give a short 'Vibe Check' of the neighborhood (e.g., 'Residential', 'Commercial', 'Quiet').
    
    Keep the response concise and friendly for a rental app user.
    """;
    
    return _getAiResponse(prompt, systemPrompt: "You are a local neighborhood expert in Nepal. You know all major landmarks and areas across Kathmandu, Lalitpur, Bhaktapur, and other major cities.");
  }
}
