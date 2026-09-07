import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

async function getAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  const formattedPrivateKey = privateKey.replace(/\\n/g, '\n')
  const rsaKey = await jose.importPKCS8(formattedPrivateKey, 'RS256')

  const jwt = await new jose.SignJWT({
    iss: clientEmail,
    sub: clientEmail,
    aud: 'https://oauth2.googleapis.com/token',
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(rsaKey)

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const data = await response.json()
  if (!response.ok) {
    throw new Error(`Failed to get OAuth token: ${JSON.stringify(data)}`)
  }

  return data.access_token
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    const { token, fcm_token, user_id, title, body, target, data: payloadData } = payload

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    let targetTokens: string[] = []

    if (token || fcm_token) {
      targetTokens.push(token || fcm_token)
    } else if (user_id) {
      const { data: userProfile } = await supabaseAdmin
        .from('profiles')
        .select('fcm_token')
        .eq('id', user_id)
        .maybeSingle()
      if (userProfile?.fcm_token) {
        targetTokens.push(userProfile.fcm_token)
      }
    } else if (target) {
      let query = supabaseAdmin.from('profiles').select('fcm_token').not('fcm_token', 'is', null)
      if (target === 'landlord') {
        query = query.eq('user_type', 'landlord')
      } else if (target === 'tenant') {
        query = query.eq('user_type', 'tenant')
      }
      const { data: profiles } = await query
      if (profiles) {
        targetTokens = profiles.map((p) => p.fcm_token).filter(Boolean)
      }
    }

    if (targetTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No target tokens found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL') || 'firebase-adminsdk-fbsvc@khozna-746e2.iam.gserviceaccount.com'
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')

    let sentCount = 0
    let errors: any[] = []

    if (privateKey) {
      const accessToken = await getAccessToken(clientEmail, privateKey)

      for (const recipientToken of targetTokens) {
        try {
          const fcmResponse = await fetch(
            'https://fcm.googleapis.com/v1/projects/khozna-746e2/messages:send',
            {
              method: 'POST',
              headers: {
                Authorization: `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                message: {
                  token: recipientToken,
                  notification: {
                    title: title || 'Khozna Notification',
                    body: body || 'You have a new update.',
                  },
                  android: {
                    priority: 'HIGH',
                    notification: {
                      channel_id: 'high_importance_channel',
                      sound: 'default',
                      default_sound: true,
                      notification_priority: 'PRIORITY_MAX',
                    },
                  },
                  apns: {
                    payload: {
                      aps: {
                        alert: {
                          title: title || 'Khozna Notification',
                          body: body || 'You have a new update.',
                        },
                        sound: 'default',
                        badge: 1,
                      },
                    },
                  },
                  data: payloadData || {},
                },
              }),
            }
          )

          if (fcmResponse.ok) {
            sentCount++
          } else {
            const errJson = await fcmResponse.json()
            errors.push(errJson)
          }
        } catch (e: any) {
          errors.push(e.message)
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sentCount,
        targetTokensCount: targetTokens.length,
        errors,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
