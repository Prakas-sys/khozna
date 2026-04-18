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
      return _error('GROQ API key not configured in .env file.');
    }

    final locationStr = (latitude != null && longitude != null)
        ? 'Lat: $latitude, Lon: $longitude'
        : 'Not provided';

    // ─── DETAILED SYSTEM PROMPT: Teach AI about Nepali citizenship card ───
    const systemPrompt = '''
You are a highly trained KYC verification specialist for Nepal, with deep expertise in Nepali government documents.

NEPALI CITIZENSHIP CARD (नागरिकता प्रमाणपत्र) — AUTHENTIC FEATURES:
You must know what a REAL Nepali citizenship card looks like:

FRONT SIDE features:
1. Header: "नेपाल सरकार" (Government of Nepal) printed at the top
2. Sub-header: "नागरिकता प्रमाणपत्र" (Citizenship Certificate)
3. Nepal government coat of arms / emblem (साल को रूख with moon and sun)
4. Issuing District name (जिल्ला) — one of Nepal's 77 districts
5. Citizenship/Serial Number (नागरिकता नम्बर) — format varies by district but typically: XX-XX-XXXXX or XX/XX-XXXXX
6. Full Name (नाम थर) in Devanagari script
7. Father's Name (बाबुको नाम) in Devanagari script
8. Grandfather's Name (बाजेको नाम) in Devanagari script
9. Permanent Address (स्थायी ठेगाना): Village/Municipality, Ward, District
10. Date of Birth (जन्म मिति) in Bikram Sambat (BS) calendar — e.g., "२०४५/०५/१५"
11. Citizenship Type: "जन्मसिद्ध" (natural born) or "वंशज" (descent)
12. A passport-style photo embedded in the card
13. Color scheme: Typically light blue, white, or cream background with blue/black text
14. Official stamp from the issuing Chief District Officer (CDO)
15. Signature of the Chief District Officer

BACK SIDE features:
1. Spouse name (पति/पत्नीको नाम) if married
2. Thumbprint / fingerprint impressions (left and right thumb)
3. Signature of the card holder
4. Issuing date and Office stamp
5. Sometimes has a photo of the holder again

SELFIE requirements:
1. A clear photo of a real human face

FAKE OR INVALID DOCUMENTS — red flags:
- Random piece of paper without official Nepali text
- A screenshot of an ID on a phone/laptop screen (not physical card)
- A photocopy of a photocopy (very low quality)
- Missing Nepali text or government seal
- Non-Nepali documents (Indian Aadhaar, Passport, Voter ID, etc.)
- Documents where the date format is not in Bikram Sambat (BS)
- No visible citizenship number
- No government emblem or header

Nepal GPS validation:
- Valid Nepal latitude range: approximately 26.3° N to 30.5° N
- Valid Nepal longitude range: approximately 80.0° E to 88.2° E
- If GPS is outside this range, flag as suspicious

IMPORTANT: Your job is to PROTECT users from fraud. Be strict. If you cannot clearly see key elements (Nepali text, government seal, citizenship number), mark it as FAIL or UNCERTAIN — not PASS.

You MUST return ONLY a valid JSON object — no markdown, no explanation, just raw JSON.
''';

    final userPrompt = '''
Analyze this KYC submission for Khozna app (Nepal property rental platform):

Submitted Details:
- Claimed Full Name: "$fullName"
- Claimed Citizenship Number: "$citizenshipNumber"
- GPS Location: $locationStr

Images to analyze:
1. Front of Citizenship Card: $frontImageUrl
2. Back of Citizenship Card: $backImageUrl
3. Selfie of the user: $selfieImageUrl

Answer these questions strictly based on what you SEE in the images:

1. Is the front image actually a Nepali नागरिकता प्रमाणपत्र (citizenship card)? Look for Nepali text, government seal, "नेपाल सरकार" header.
2. Does the name on the card match "$fullName"?
3. Does the citizenship number on the card match "$citizenshipNumber"?
4. Does the selfie clearly show a real human face?
5. Is the GPS location within Nepal's boundaries (lat 26-30, lon 80-88)?
6. Are there any red flags suggesting the documents are fake?

Return ONLY this exact JSON:
{
  "verdict": "PASS" or "FAIL" or "UNCERTAIN",
  "confidence": <0-100>,
  "is_genuine_nepali_id": true or false,
  "name_match": true or false,
  "id_number_match": true or false,
  "human_face_in_selfie": true or false,
  "location_valid": true or false,
  "red_flags": ["<flag 1>", "<flag 2>"],
  "notes": "<brief explanation of your verdict in 1-2 sentences>"
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
                    {'type': 'image_url', 'image_url': {'url': frontImageUrl}},
                    {'type': 'image_url', 'image_url': {'url': backImageUrl}},
                    {'type': 'image_url', 'image_url': {'url': selfieImageUrl}},
                  ],
                },
              ],
              'temperature': 0.1, // Very low — we want strict deterministic analysis
              'max_tokens': 600,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        // Strip markdown code fences if AI adds them
        content = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        // Extract JSON from response (in case AI adds extra text)
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}');
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          content = content.substring(jsonStart, jsonEnd + 1);
        }
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        return _error('AI service error (${response.statusCode}). Try again.');
      }
    } catch (e) {
      return _error('Connection error: ${e.toString().split('\n').first}');
    }
  }

  static Map<String, dynamic> _error(String message) => {
        'verdict': 'ERROR',
        'confidence': 0,
        'is_genuine_nepali_id': false,
        'name_match': false,
        'id_number_match': false,
        'human_face_in_selfie': false,
        'location_valid': false,
        'red_flags': [message],
        'notes': message,
      };
}
