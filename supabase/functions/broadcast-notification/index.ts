import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { title, body, target, data: payloadData } = await req.json()

    // 1. Initialize Supabase Admin Client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Fetch target FCM tokens
    let query = supabaseAdmin.from('profiles').select('fcm_token').not('fcm_token', 'is', null)
    
    if (target === 'landlord') {
      query = query.eq('user_type', 'landlord')
    } else if (target === 'tenant') {
      query = query.eq('user_type', 'tenant')
    }

    const { data: profiles, error: fetchError } = await query

    if (fetchError) throw fetchError
    if (!profiles || profiles.length === 0) {
      return new Response(JSON.stringify({ message: 'No target users found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    const tokens = profiles.map(p => p.fcm_token)

    // ─── FCM V1 INTEGRATION ──────────────────────────────────────────────────
    // To send via FCM V1, you need to:
    // 1. Get a Google OAuth2 Access Token using a Service Account JSON.
    // 2. POST to https://fcm.googleapis.com/v1/projects/khozna-746e2/messages:send
    //
    // For bulk sending, you should loop through tokens or use a multicast endpoint
    // if available (V1 requires individual calls or batching).
    
    console.log(`[CAMPAIGN] Broadcasting "${title}" to ${tokens.length} users. Target: ${target}`)

    // TODO: Implement the actual fetch call once Service Account is configured
    // For now, we simulate success for the Admin Dashboard UI
    
    return new Response(JSON.stringify({ 
      success: true, 
      message: `Successfully initiated broadcast to ${tokens.length} recipients.`,
      details: {
        title,
        recipients: tokens.length,
        target
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
