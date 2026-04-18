// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req: Request) => {
  try {
    const payload = await req.json()
    const record = payload.record
    if (!record) throw new Error("No record")

    // @ts-ignore: Deno is a global in this environment
    const groqKey = Deno.env.get("GROQ_API_KEY")
    // @ts-ignore
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    // @ts-ignore
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    console.log("Upgraded Llama-4 Brain for user: " + record.id)

    const groqResponse = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": "Bearer " + groqKey },
      body: JSON.stringify({
        model: "meta-llama/llama-4-scout-17b-16e-instruct",
        messages: [{ role: "user", content: [
          { type: "text", text: "Analyze this Nepali ID. Return in this JSON format: {\"verdict\": \"PASS\" or \"FAIL\", \"reason\": \"Short reason in Nepali why it failed or null if pass\"}. User Name: " + record.full_name },
          { type: "image_url", image_url: { url: record.front_image_url } }
        ]}],
        max_tokens: 100,
        response_format: { type: "json_object" }
      })
    })

    const bodyText = await groqResponse.text()
    if (!groqResponse.ok) throw new Error("Groq API Error: " + bodyText)

    const aiData = JSON.parse(bodyText)
    const aiResult = JSON.parse(aiData.choices?.[0]?.message?.content || "{\"verdict\": \"FAIL\", \"reason\": \"प्रमाणिकरण त्रुटि\"}")
    
    const verdict = aiResult.verdict.toLowerCase() === "pass" ? "verified" : "rejected"
    const reason = aiResult.reason || "कागजातहरू स्पष्ट छैनन्।"

    await supabase.from("kyc_verifications").update({ 
      status: verdict, 
      rejection_reason: verdict === "rejected" ? reason : null 
    }).eq("id", record.id)
    
    await supabase.from("profiles").update({ kyc_status: verdict }).eq("id", record.user_id)
    
    await supabase.from("notifications").insert({
      user_id: record.user_id,
      sender_id: record.user_id,
      title: verdict === "verified" ? "Verification Successful! 🎉" : "Verification Failed ⚠️",
      message: verdict === "verified" 
        ? "तपाइँको पहिचान प्रमाणित भयो। तपाइँ अब Khozna का सबै सुविधाहरू प्रयोग गर्न सक्नुहुन्छ।" 
        : `कारण: ${reason}। कृपया पुन: प्रयास गर्नुहोस्।`,
      type: "system"
    })

    return new Response(JSON.stringify({ success: true, verdict, reason }), { status: 200 })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err)
    console.error("Auto-Pilot Error:", message)
    return new Response(JSON.stringify({ error: message }), { status: 200 })
  }
})
