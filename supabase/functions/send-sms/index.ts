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
    const { phone, metadata } = await req.json()
    const otp = metadata.otp // Supabase passes the OTP in metadata
    const auth_token = Deno.env.get("AAKASH_SMS_TOKEN")

    if (!auth_token) {
      throw new Error("Missing AAKASH_SMS_TOKEN secret")
    }

    // Aakash SMS API v3 endpoint
    const url = "http://aakashsms.com/admin/public/sms/v3/send/"

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

    const result = await response.json()
    console.log("Aakash SMS Response:", result)

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })
  } catch (error) {
    console.error("SMS Hook Error:", error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    })
  }
})
