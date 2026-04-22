import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.42.7'

// --- KHOZNA AI AUTO-PILOT (V8.3 - DEBUG) ---

const cleanJsonResponse = (text: string) => {
  try {
    const jsonMatch = text.match(/```json\n([\s\S]*?)\n```/) || text.match(/{[\s\S]*}/);
    if (jsonMatch) return JSON.parse(jsonMatch[1] || jsonMatch[0]);
    return JSON.parse(text);
  } catch (e) {
    throw new Error(`Invalid JSON from AI: ${text.slice(0, 100)}`);
  }
};

serve(async (req: Request) => {
  const requestId = crypto.randomUUID().slice(0, 8);
  console.log(`[${requestId}] 🚀 Triggered`);

  try {
    const payload = await req.json();
    const record = payload.record;
    if (!record) return new Response("No record", { status: 400 });

    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (!groqKey) throw new Error("GROQ_API_KEY missing");

    console.log(`[${requestId}] 🤖 Calling Groq (llama-3.2-11b-vision-preview)...`);

    const systemPrompt = `You are a KYC Officer. Verify the Nepali Citizenship ID. Compare CLAIMED ID with ID on card.
    EXTRACT ID, CONVERT digits to English.
    OUTPUT JSON: {"verdict": "PASS" | "FAIL", "confidence": 0-100, "reason": "Nepali reason"}`;

    const userPrompt = `CLAIMED ID: ${record.citizenship_number}`;

    const groqResponse = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${groqKey}` },
      body: JSON.stringify({
        model: "llama-3.2-11b-vision-preview",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: [
            { type: "text", text: userPrompt },
            { type: "image_url", image_url: { url: record.front_image_url } },
            { type: "image_url", image_url: { url: record.back_image_url } },
            { type: "image_url", image_url: { url: record.selfie_image_url } }
          ]}
        ],
        temperature: 0.1
        // Removed response_format to avoid potential model compatibility issues
      })
    });

    if (!groqResponse.ok) {
      const errorData = await groqResponse.json();
      throw new Error(`Groq API Error: ${JSON.stringify(errorData)}`);
    }

    const data = await groqResponse.json();
    const content = data.choices?.[0]?.message?.content || "{}";
    console.log(`[${requestId}] 🤖 Raw AI Response:`, content);
    
    const result = cleanJsonResponse(content);
    console.log(`[${requestId}] ✅ Decision: ${result.verdict} (${result.confidence}%)`);

    const finalStatus = (result.verdict === "PASS" && result.confidence >= 80) ? "verified" : "rejected";

    // DB Updates
    console.log(`[${requestId}] ⚙️ Updating DB: ${finalStatus}`);
    await supabase.from("kyc_verifications").update({ 
      status: finalStatus,
      rejection_reason: finalStatus === "rejected" ? result.reason : null 
    }).eq("id", record.id);

    await supabase.from("profiles").update({ kyc_status: finalStatus }).eq("id", record.user_id);
    
    await supabase.from("notifications").insert({
      user_id: record.user_id,
      title: finalStatus === "verified" ? "KYC Approved! ✅" : "KYC Rejected ❌",
      message: finalStatus === "verified" 
        ? "बधाई छ! तपाईंको पहिचान प्रमाणित भएको छ।" 
        : `तपाईंको पहिचान पुष्टि हुन सकेन। कारण: ${result.reason}`,
      type: "kyc_update"
    });

    console.log(`[${requestId}] 🔔 Notification sent`);
    return new Response(JSON.stringify({ success: true, verdict: result.verdict }), { status: 200 });

  } catch (err: any) {
    console.error(`[${requestId}] 💥 Error:`, err.message);
    
    // DEBUG: Log error to notifications for the admin profile
    try {
      const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
      await supabase.from("notifications").insert({
        user_id: '27a768e9-cf28-4a2c-b4f9-cb27749bb6ca', // The "Khozna app" profile ID
        title: "KYC Error Log",
        message: `Error in requestId ${requestId}: ${err.message}`,
        type: "system_error"
      });
    } catch (e) {
      console.error("Failed to log error to DB:", e);
    }

    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
})
