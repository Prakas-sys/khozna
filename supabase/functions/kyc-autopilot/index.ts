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
          { type: "text", text: "Is this a valid Nepali ID? Return ONLY 'PASS' or 'FAIL'. User: " + record.full_name },
          { type: "image_url", image_url: { url: record.front_image_url } }
        ]}],
        max_tokens: 10
      })
    })

    const bodyText = await groqResponse.text()
    if (!groqResponse.ok) throw new Error("Groq API Error: " + bodyText)

    const aiData = JSON.parse(bodyText)
    const rawContent = aiData.choices[0].message.content
    const verdict = rawContent.includes("PASS") ? "verified" : "rejected"

    await supabase.from("kyc_verifications").update({ status: verdict }).eq("id", record.id)
    await supabase.from("profiles").update({ kyc_status: verdict }).eq("id", record.user_id)
    
    await supabase.from("notifications").insert({
      user_id: record.user_id,
      sender_id: record.user_id,
      title: verdict === "verified" ? "Verification Successful! 🎉" : "Verification Failed ⚠️",
      message: verdict === "verified" 
        ? "Your identity has been successfully verified. You now have full access to Khozna." 
        : "We couldn't verify your documents. Please check the details and try again.",
      type: "system"
    })

    return new Response(JSON.stringify({ success: true, verdict }), { status: 200 })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err)
    console.error("Auto-Pilot Error:", message)
    return new Response(JSON.stringify({ error: message }), { status: 200 })
  }
})
