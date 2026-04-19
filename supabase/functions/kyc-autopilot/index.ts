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
You are an expert KYC verification AI specializing in Nepali Citizen Identity Cards (नागरिकता प्रमाणपत्र).
YOUR GOAL: Highly accurate verification to prevent fraud.

NEPALI ID CHECKS:
1. Must have "नेपाल सरकार" and Government Emblem.
2. Must have Devanagari text for name and address.
3. Number format: XX-XX-XXXXX or XX/XX-XXXXX.
4. Selfie must match the person on the ID card.

TRUST LEVELS:
- PASS: Everything matches (Name, ID number, face), and document is genuine.
- FAIL: Blurred, fake, incorrect details, or non-Nepali ID.
- UNCERTAIN: High doubt or bad lighting.
`;

    const userPrompt = `
Analyze this Khozna submission:
Name: "${record.full_name}"
ID No: "${record.citizenship_number}"

Images:
- Front: ${record.front_image_url}
- Back: ${record.back_image_url}
- Selfie: ${record.selfie_image_url}

Return JSON ONLY:
{
  "verdict": "PASS" | "FAIL" | "UNCERTAIN",
  "confidence": 0-100,
  "reason": "Brief reason in Nepali"
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
