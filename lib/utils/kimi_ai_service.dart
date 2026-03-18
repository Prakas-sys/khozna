import 'dart:convert';
import 'package:http/http.dart' as http;

class KimiAiService {
  static const String _baseUrl = 'https://api.moonshot.cn/v1/chat/completions';
  
  final String apiKey = 'sk-Bst5JnSq2fUBCoTWDE5VRmiM3z7g9cWNFtyTPCcJ5Vh6saFq';

  /// 100% Cloud AI Request (Always On)
  Future<String> _getAiResponse(String prompt, {required String systemPrompt}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'moonshot-v1-8k', 
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
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

  /// 1. AI Property Matching (Natural Language Search)
  Future<String> matchProperty(String userQuery, List<Map<String, dynamic>> properties) async {
    String propertyData = properties.map((p) => 
      "ID: ${p['id']}, Title: ${p['title']}, Price: ${p['price']}, Location: ${p['location']}"
    ).join("\n");

    String prompt = """
    A user is looking for: "$userQuery"
    Listing context:
    $propertyData
    Find best matches and explain why. Keep it in Nepali/English mix for Nepal market.
    """;

    return _getAiResponse(prompt, systemPrompt: "Property matching expert for Khozna Nepal.");
  }

  /// 2. AI Scam Detector
  Future<String> detectScam(String title, String price, String area) async {
    String prompt = "Title: $title, Price: $price, Area: $area. Is this a rental scam in Nepal?";
    return _getAiResponse(prompt, systemPrompt: "Security expert for Nepal rentals.");
  }

  /// 3. AI Price Estimator
  Future<String> estimatePrice(String location, int rooms, String type) async {
    String prompt = "Fair price for $rooms room $type in $location, Nepal?";
    return _getAiResponse(prompt, systemPrompt: "Real estate valuation expert for Nepal.");
  }

  /// 4. AI Chatbot
  Future<String> getChatbotResponse(String userMessage) async {
    return _getAiResponse(userMessage, systemPrompt: "You are the Khozna AI Assistant. Help users with rentals in Nepal. Be friendly!");
  }
}
