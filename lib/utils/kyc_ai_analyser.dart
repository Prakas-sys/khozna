import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class KycAiAnalyser {
  static const String _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _visionModel = 'llama-3.2-90b-vision-preview';

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// Analyse KYC documents using GROQ Vision AI
  static Future<Map<String, dynamic>> analyseKycDocuments({
    required String frontImageUrl,
    required String backImageUrl,
    required String selfieImageUrl,
    required String fullName,
    required String citizenshipNumber,
    double? latitude,
    double? longitude,
  }) async {
    if (_apiKey.isEmpty) {
      return {
        'verdict': 'ERROR',
        'confidence': 0,
        'reasons': ['GROQ API key not configured.'],
        'name_match': false,
        'id_visible': false,
        'face_match': false,
        'location_valid': false,
      };
    }

    final locationStr = (latitude != null && longitude != null)
        ? '$latitude, $longitude'
        : 'Not provided';

    final systemPrompt = '''
You are an expert KYC verification officer for Khozna, a Nepali property rental app.
Your job is to analyze citizenship documents submitted by users in Nepal.
You MUST return ONLY a valid JSON object — no markdown, no explanation, just JSON.
''';

    final userPrompt = '''
Analyze the following KYC submission for a Nepali user:

User-Provided Details:
- Full Name: $fullName
- Citizenship Number: $citizenshipNumber
- GPS Location: $locationStr

Documents (analyze carefully):
1. Front of Citizenship ID: $frontImageUrl
2. Back of Citizenship ID: $backImageUrl
3. Selfie (user holding ID next to face): $selfieImageUrl

Verification Checklist:
- Does the name on the ID match the provided name "$fullName"?
- Is the citizenship number "$citizenshipNumber" visible and matching on the ID?
- Is the face in the selfie clearly visible and holding the ID document?
- Is the GPS location valid for Nepal (roughly lat 26-30, lon 80-88)?
- Are the documents genuine-looking (not photocopied/screenshotted photos)?

Return ONLY this JSON (no other text):
{
  "verdict": "PASS" or "FAIL" or "UNCERTAIN",
  "confidence": <number 0-100>,
  "reasons": ["<reason 1>", "<reason 2>"],
  "name_match": true or false,
  "id_visible": true or false,
  "face_match": true or false,
  "location_valid": true or false
}
''';

    try {
      final response = await http
          .post(
            Uri.parse(_groqUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _visionModel,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': userPrompt},
                    {
                      'type': 'image_url',
                      'image_url': {'url': frontImageUrl}
                    },
                    {
                      'type': 'image_url',
                      'image_url': {'url': backImageUrl}
                    },
                    {
                      'type': 'image_url',
                      'image_url': {'url': selfieImageUrl}
                    },
                  ],
                },
              ],
              'temperature': 0.1,
              'max_tokens': 512,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        // Strip any markdown code fences if AI adds them
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        return {
          'verdict': 'ERROR',
          'confidence': 0,
          'reasons': ['AI service returned status ${response.statusCode}. Try again.'],
          'name_match': false,
          'id_visible': false,
          'face_match': false,
          'location_valid': false,
        };
      }
    } catch (e) {
      return {
        'verdict': 'ERROR',
        'confidence': 0,
        'reasons': ['Connection error: $e'],
        'name_match': false,
        'id_visible': false,
        'face_match': false,
        'location_valid': false,
      };
    }
  }
}
