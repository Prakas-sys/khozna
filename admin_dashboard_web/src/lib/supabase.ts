import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://qjpeablwokiuhfaopdbi.supabase.co'
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqcGVhYmx3b2tpdWhmYW9wZGJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NjkxMjgsImV4cCI6MjA4NzE0NTEyOH0.Sz3K67ClV8ZfgCdabA_cFfh_wa6X-Q-fHylYJ8utTLI'
const supabaseServiceKey = import.meta.env.VITE_SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqcGVhYmx3b2tpdWhmYW9wZGJpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTU2OTEyOCwiZXhwIjoyMDg3MTQ1MTI4fQ.ZyV6x5yvPaKxITcpOeBVHsbefVirDem5qrRiruYQnN8'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Admin client with service role — used only in admin dashboard for privileged ops
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
})

