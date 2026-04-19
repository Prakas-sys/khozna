-- ==========================================
-- KHOZNA AI AUTO-PILOT TRIGGER
-- ==========================================

-- 1. Create a function to call the Edge Function
CREATE OR REPLACE FUNCTION public.handle_kyc_autopilot()
RETURNS TRIGGER AS $$
BEGIN
  -- Perform an asynchronous HTTP request to the Edge Function
  -- We use the service role key to bypass RLS if needed
  PERFORM
    net.http_post(
      url := 'https://qjpeablwokiuhfaopdbi.supabase.co/functions/v1/kyc-autopilot',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      ),
      body := jsonb_build_object('record', row_to_json(NEW))
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attach the trigger to kyc_verifications
-- Only trigger on INSERT (when a user first submits)
DROP TRIGGER IF EXISTS on_kyc_submitted ON public.kyc_verifications;
CREATE TRIGGER on_kyc_submitted
  AFTER INSERT ON public.kyc_verifications
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_kyc_autopilot();

-- Note: Ensure the 'net' extension is enabled in your Supabase dashboard
-- and the 'app.settings.service_role_key' is set in your Postgres config
-- or replace it with your actual service role key string if preferred.
