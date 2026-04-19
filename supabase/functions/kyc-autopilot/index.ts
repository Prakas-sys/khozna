import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// --- AI AUTO-PILOT SYSTEM (V2) ---
// Model: Llama-3.2-90b-Vision
// Logic: Advanced Nepali Document Verification

serve(async (req: Request) => {
  try {
    const payload = await req.json()
    const record = payload.record // Triggered by NEW kyc_verifications row
    if (!record) throw new Error("No record found in payload")

    // Environment Keys
    const groqKey = Deno.env.get("VITE_GROQ_API_KEY") || Deno.env.get("GROQ_API_KEY")
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    console.log(`🚀 AI Auto-Pilot: Analysing KYC for ${record.full_name} (${record.id})`);

    const systemPrompt = `
You are a strict Security Officer AI for Khozna platform. Your specialty is verifying Nepali Citizenship Certificates (नागरिकता प्रमाणपत्र).

CRITICAL INSTRUCTIONS:
1. EXTRACT CITIZENSHIP NUMBER: You MUST find and read the Citizenship Number (प्रमाणपत्र नं.) directly from both the FRONT and BACK of the ID.
2. CROSS-REFERENCE: Compare the number you extracted from the card with the one provided by the user.
3. FAIL ON MISMATCH: Even if the person's name matches, if the Citizenship Number on the ID card is different from the number provided in text, it is a FRAUD ATTEMPT. Verdict must be "FAIL".
4. NEPALI NUMERALS: Be expert at reading Devanagari digits (०=0, १=1, २=2, ३=3, ४=4, ५=5, ६=6, ७=7, ८=8, ९=9).
5. VISUAL INTEGRITY: Check for signs of Photoshop or "edited" text.
6. FACE MATCH: Ensure the selfie is 100% the same person as the ID card photo.

VERDICT RULES:
- PASS: Perfect match of ID Number (Card vs Text), Name, and Face.
- FAIL: ID Number mismatch, fake document, or face mismatch.
- UNCERTAIN: Only for blurred/unreadable images. Never pass if you can't read the number.
`;

    const userPrompt = `
SECURITY TASK: Verify if the document in these images belongs to "${record.full_name}" and strictly matches the ID number provided below.

CLAIMED NAME: "${record.full_name}"
CLAIMED CITIZENSHIP NO: "${record.citizenship_number}"

IMAGE URLS TO SCAN:
- Front: ${record.front_image_url}
- Back: ${record.back_image_url}
- Selfie: ${record.selfie_image_url}

OUTPUT JSON ONLY:
{
  "verdict": "PASS" | "FAIL" | "UNCERTAIN",
  "confidence": 0-100,
  "extracted_number_from_card": "The number you actually saw on the card",
  "reason": "Detailed reason in Nepali. Mention specifically if the numbers matched or not."
}
`;

    const groqResponse = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { 
        "Content-Type": "application/json", 
        "Authorization": `Bearer ${groqKey}` 
      },
      body: JSON.stringify({
        model: "llama-3.2-90b-vision-preview",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: [
            { type: "text", text: userPrompt },
            { type: "image_url", image_url: { url: record.front_image_url } },
            { type: "image_url", image_url: { url: record.back_image_url } },
            { type: "image_url", image_url: { url: record.selfie_image_url } }
          ]}
        ],
        temperature: 0.1,
        response_format: { type: "json_object" }
      })
    })

    if (!groqResponse.ok) throw new Error(`Groq API returned ${groqResponse.status}`);
    
    const data = await groqResponse.json();
    const aiResult = JSON.parse(data.choices?.[0]?.message?.content || "{}");
    
    console.log(`🤖 AI Decision: ${aiResult.verdict} (Confidence: ${aiResult.confidence}%)`);

    // --- AUTO-ACTION LOGIC ---
    // Threshold: 90% for automatic processing
    let finalStatus = "pending";
    let rejectionReason = aiResult.reason;

    if (aiResult.verdict === "PASS" && aiResult.confidence >= 90) {
      finalStatus = "verified";
    } else if (aiResult.verdict === "FAIL" && aiResult.confidence >= 90) {
      finalStatus = "rejected";
    }

    // Update DB if we made a firm decision
    if (finalStatus !== "pending") {
      await supabase.from("kyc_verifications").update({ 
        status: finalStatus, 
        rejection_reason: finalStatus === "rejected" ? rejectionReason : null 
      }).eq("id", record.id);
      
      await supabase.from("profiles").update({ kyc_status: finalStatus }).eq("id", record.user_id);
      
      // Notify User
      await supabase.from("notifications").insert({
        user_id: record.user_id,
        title: finalStatus === "verified" ? "KYC Approved! ✅" : "KYC Rejected ❌",
        message: finalStatus === "verified" 
          ? "बधाई छ! तपाईंको पहिचान प्रमाणित भएको छ।" 
          : `तपाईंको कागजात अस्वीकार गरियो। कारण: ${rejectionReason}`,
        type: "kyc_update"
      });
    }

    return new Response(JSON.stringify({ success: true, ai_verdict: aiResult.verdict }), { status: 200 });
  } catch (err: any) {
    console.error("Auto-Pilot Error:", err.message);
    return new Response(JSON.stringify({ error: err.message }), { status: 200 });
  }
})
