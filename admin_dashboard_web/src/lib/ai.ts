const GROQ_API_KEY = import.meta.env.VITE_GROQ_API_KEY;
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const VISION_MODEL = 'llama-3.2-90b-vision-preview';

export interface AiKycResult {
  verdict: 'PASS' | 'FAIL' | 'UNCERTAIN' | 'ERROR';
  confidence: number;
  is_genuine_nepali_id: boolean;
  name_match: boolean;
  id_number_match: boolean;
  human_face_in_selfie: boolean;
  location_valid: boolean;
  red_flags: string[];
  notes: string;
}

export const analyseKycDocuments = async (params: {
  frontImageUrl: string;
  backImageUrl: string;
  selfieImageUrl: string;
  fullName: string;
  citizenshipNumber: string;
  latitude?: number;
  longitude?: number;
}): Promise<AiKycResult> => {
  if (!GROQ_API_KEY) {
    return createErrorResult('GROQ API key missing in environment.');
  }

  const locationStr = (params.latitude && params.longitude)
    ? `Lat: ${params.latitude}, Lon: ${params.longitude}`
    : 'Not provided';

  const systemPrompt = `
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
7. Date of Birth (जन्म मिति) in Bikram Sambat (BS) calendar — e.g., "२०४५/०५/१५"
8. Official stamp from the issuing Chief District Officer (CDO)

SELFIE requirements:
1. A clear photo of a real human face

IMPORTANT: Be strict. If you cannot clearly see key elements (Nepali text, government seal, citizenship number), mark it as FAIL or UNCERTAIN — not PASS.

You MUST return ONLY a valid JSON object.
`;

  const userPrompt = `
Analyze this KYC submission for Khozna app:

Submitted Details:
- Claimed Full Name: "${params.fullName}"
- Claimed Citizenship Number: "${params.citizenshipNumber}"
- GPS Location: ${locationStr}

Images to analyze:
1. Front of Citizenship Card: ${params.frontImageUrl}
2. Back of Citizenship Card: ${params.backImageUrl}
3. Selfie of the user: ${params.selfieImageUrl}

Return ONLY this exact JSON structure:
{
  "verdict": "PASS" or "FAIL" or "UNCERTAIN",
  "confidence": <0-100>,
  "is_genuine_nepali_id": true or false,
  "name_match": true or false,
  "id_number_match": true or false,
  "human_face_in_selfie": true or false,
  "location_valid": true or false,
  "red_flags": ["reason 1", "reason 2"],
  "notes": "brief summary"
}
`;

  try {
    const response = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${GROQ_API_KEY}`
      },
      body: JSON.stringify({
        model: VISION_MODEL,
        messages: [
          { role: 'system', content: systemPrompt },
          {
            role: 'user',
            content: [
              { type: 'text', text: userPrompt },
              { type: 'image_url', image_url: { url: params.frontImageUrl } },
              { type: 'image_url', image_url: { url: params.backImageUrl } },
              { type: 'image_url', image_url: { url: params.selfieImageUrl } }
            ]
          }
        ],
        temperature: 0.1,
        max_tokens: 600
      })
    });

    if (!response.ok) {
      return createErrorResult(`AI service error (${response.status})`);
    }

    const data = await response.json();
    let content = data.choices[0].message.content;

    // Clean JSON response
    content = content.replace(/```json/g, '').replace(/```/g, '').trim();
    const jsonStart = content.indexOf('{');
    const jsonEnd = content.lastIndexOf('}');
    if (jsonStart !== -1 && jsonEnd !== -1) {
      content = content.substring(jsonStart, jsonEnd + 1);
    }

    return JSON.parse(content) as AiKycResult;
  } catch (error: any) {
    return createErrorResult(error.message || 'Connection error');
  }
};

const createErrorResult = (message: string): AiKycResult => ({
  verdict: 'ERROR',
  confidence: 0,
  is_genuine_nepali_id: false,
  name_match: false,
  id_number_match: false,
  human_face_in_selfie: false,
  location_valid: false,
  red_flags: [message],
  notes: message
});
