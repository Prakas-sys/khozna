import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

/**
 * Aakash SMS Integration for Supabase Auth Hook
 * 
 * To use this:
 * 1. Deploy this function via Supabase CLI
 * 2. Set AAKASH_SMS_TOKEN in your Supabase Project Settings > Edge Functions > Secrets
 */

serve(async (req) => {
  try {
    const payload = await req.json()
    
    // Supabase Auth Hook Send SMS Payload Structure:
    // { "user": { "phone": "+977..." }, "sms": { "otp": "123456" } }
    const phone = payload.user?.phone || payload.phone
    const otp = payload.sms?.otp || (payload.metadata && payload.metadata.otp)
    
    const auth_token = Deno.env.get("AAKASH_SMS_TOKEN")

    if (!auth_token) {
      throw new Error("Missing AAKASH_SMS_TOKEN secret")
    }

    // Aakash SMS API v3 endpoint
    const url = "https://sms.aakashsms.com/sms/v3/send"

    // Clean phone number (Aakash SMS expects 10 digits, strip +977 if present)
    const cleanPhone = phone.replace("+977", "").trim()

    const formData = new FormData()
    formData.append("auth_token", auth_token)
    formData.append("to", cleanPhone)
    formData.append("text", `Your Khozna OTP code is: ${otp}. Do not share this with anyone.`)

    const response = await fetch(url, {
      method: "POST",
      body: formData,
    })

    const responseText = await response.text()
    try {
      const result = JSON.parse(responseText)
      console.log("Aakash SMS Response:", result)
      
      return new Response(JSON.stringify(result), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      })
    } catch (err) {
      console.error("Aakash SMS returned non-JSON:", responseText)
      return new Response(JSON.stringify({ success: false, raw: responseText }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      })
    }

  } catch (error) {
    console.error("SMS Hook Error:", error.message)
    // Always return 200 with JSON so Supabase Auth doesn't crash the Flutter client
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })
  }
})
