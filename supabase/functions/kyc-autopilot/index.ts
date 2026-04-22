import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// --- KHOZNA AI AUTO-PILOT (V8 - LLAMA 4) ---
// Model: meta-llama/llama-4-scout-17b-16e-instruct
// Logic: Advanced Nepali Document Verification with Llama 4 Vision

serve(async (req: Request) => {
  const requestId = crypto.randomUUID().slice(0, 8);
  console.log(`[${requestId}] 🚀 AI Auto-Pilot Triggered`);

  try {
    const payload = await req.json()
    const record = payload.record // Triggered by NEW kyc_verifications row
    
    if (!record) {
      console.error(`[${requestId}] ❌ Error: No record found in payload`);
      return new Response(JSON.stringify({ error: "No record found" }), { status: 400 });
    }

    // Environment Keys
    const groqKey = Deno.env.get("GROQ_API_KEY") || Deno.env.get("VITE_GROQ_API_KEY")
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    if (!groqKey) {
      console.error(`[${requestId}] ❌ Error: GROQ_API_KEY missing`);
      throw new Error("GROQ_API_KEY not configured");
    }

    console.log(`[${requestId}] 🔍 Analysing KYC for ${record.full_name} (${record.id})`);
    console.log(`[${requestId}] 📄 Claimed ID: ${record.citizenship_number}`);

    const systemPrompt = `
You are a HIGH-SECURITY Compliance Officer for Khozna. Your task is to verify Nepali Citizenship Certificates.

CRITICAL INSTRUCTIONS:
1. EXTRACT ID: You MUST find the Citizenship Number (प्रमाणपत्र नं.) on both FRONT and BACK images.
2. CONVERT NEPALI: If numbers are in Devanagari (०-९), convert them to (0-9).
3. COMPARE: If the extracted number does NOT 100% match the CLAIMED ID provided, you MUST FAIL.
4. FACE MATCH: Ensure the user's selfie matches the photo on the ID card.
5. SIGNS OF TAMPERING: Check for digital edits or "fake" IDs.

OUTPUT JSON ONLY:
{
  "verdict": "PASS" | "FAIL" | "UNCERTAIN",
  "confidence": 0-100,
  "extracted_id_from_card": "the digits you actually saw",
  "reason": "Detailed reason in Nepali. Explain why it matched or why it failed."
}
`;

    const userPrompt = `
CLAIMED NAME: "${record.full_name}"
CLAIMED ID: "${record.citizenship_number}"

IMAGE URLS:
- Front: ${record.front_image_url}
- Back: ${record.back_image_url}
- Selfie: ${record.selfie_image_url}
`;

    console.log(`[${requestId}] 🤖 Sending request to Groq (Llama 4 Vision)...`);

    const groqResponse = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { 
        "Content-Type": "application/json", 
        "Authorization": `Bearer ${groqKey}` 
      },
      body: JSON.stringify({
        model: "meta-llama/llama-4-scout-17b-16e-instruct",
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

    if (!groqResponse.ok) {
      const errorText = await groqResponse.text();
      console.error(`[${requestId}] ❌ Groq API Error: ${groqResponse.status} - ${errorText}`);
      throw new Error(`AI Engine Error: ${groqResponse.status}`);
    }
    
    const data = await groqResponse.json();
    const aiResult = JSON.parse(data.choices?.[0]?.message?.content || "{}");
    
    console.log(`[${requestId}] ✅ AI Decision: ${aiResult.verdict} (Confidence: ${aiResult.confidence}%)`);
    console.log(`[${requestId}] 📝 Extracted Number: ${aiResult.extracted_id_from_card}`);

    // --- AUTO-ACTION LOGIC ---
    let finalStatus = "pending";
    if (aiResult.verdict === "PASS" && aiResult.confidence >= 90) {
      finalStatus = "verified";
    } else if (aiResult.verdict === "FAIL" && aiResult.confidence >= 80) {
      finalStatus = "rejected";
    }

    if (finalStatus !== "pending") {
      console.log(`[${requestId}] ⚙️ Updating DB: ${finalStatus}`);
      
      await supabase.from("kyc_verifications").update({ 
        status: finalStatus, 
        rejection_reason: finalStatus === "rejected" ? aiResult.reason : null 
      }).eq("id", record.id);
      
      await supabase.from("profiles").update({ kyc_status: finalStatus }).eq("id", record.user_id);
      
      // Notify User
      await supabase.from("notifications").insert({
        user_id: record.user_id,
        title: finalStatus === "verified" ? "KYC Approved! ✅" : "KYC Rejected ❌",
        message: finalStatus === "verified" 
          ? "बधाई छ! तपाईंको पहिचान प्रमाणित भएको छ।" 
          : `तपाईंको पहिचान पुष्टि हुन सकेन। कारण: ${aiResult.reason}`,
        type: "kyc_update"
      });
    } else {
      console.log(`[${requestId}] ⏸️ Result is UNCERTAIN. Leaving for manual audit.`);
    }

    return new Response(JSON.stringify({ success: true, verdict: aiResult.verdict }), { status: 200 });
  } catch (err: any) {
    console.error(`[${requestId}] 💥 Fatal Error:`, err.message);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
})
