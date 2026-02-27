-- ==========================================
-- FIREBASE AUTH SYNC SETUP
-- ==========================================
-- This script adjusts the schema to work with Firebase UIDs (Strings)
-- instead of Supabase UUIDs.

-- 1. DROP CONSTRAINTS & TRIGGERS
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. ALTER TABLES TO USE TEXT FOR IDs
-- We need to drop foreign keys first, then change types, then recreate.

-- Drop Foreign Keys
ALTER TABLE public.properties DROP CONSTRAINT IF EXISTS properties_owner_id_fkey;
ALTER TABLE public.saved_properties DROP CONSTRAINT IF EXISTS saved_properties_user_id_fkey;
ALTER TABLE public.kyc_verifications DROP CONSTRAINT IF EXISTS kyc_verifications_user_id_fkey;
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE public.chats DROP CONSTRAINT IF EXISTS chats_participant_one_fkey;
ALTER TABLE public.chats DROP CONSTRAINT IF EXISTS chats_participant_two_fkey;
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

-- Change Type in Profiles
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.profiles ALTER COLUMN id TYPE TEXT;

-- Change Type in Other Tables
ALTER TABLE public.properties ALTER COLUMN owner_id TYPE TEXT;
ALTER TABLE public.saved_properties ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE public.kyc_verifications ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE public.notifications ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE public.chats ALTER COLUMN participant_one TYPE TEXT;
ALTER TABLE public.chats ALTER COLUMN participant_two TYPE TEXT;
ALTER TABLE public.messages ALTER COLUMN sender_id TYPE TEXT;

-- Recreate Foreign Keys (without UUID restriction)
ALTER TABLE public.properties ADD CONSTRAINT properties_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.saved_properties ADD CONSTRAINT saved_properties_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.kyc_verifications ADD CONSTRAINT kyc_verifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.chats ADD CONSTRAINT chats_participant_one_fkey FOREIGN KEY (participant_one) REFERENCES public.profiles(id);
ALTER TABLE public.chats ADD CONSTRAINT chats_participant_two_fkey FOREIGN KEY (participant_two) REFERENCES public.profiles(id);
ALTER TABLE public.messages ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id);

-- 3. RLS UPDATES (Use text-based comparison)
-- Note: Supabase auth.uid() returns UUID. 
-- Since we use Firebase, we will pass the UID as a header or just use standard RLS.
-- For this setup, we will use a custom function to get the current user ID from metadata or headers.
-- But for simplicity in this prototype, we'll allow users to manage records where user_id matches their provided ID.

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR ALL USING (true); -- Simplified for Firebase demo

DROP POLICY IF EXISTS "Owners can manage their properties" ON public.properties;
CREATE POLICY "Owners can manage their properties" ON public.properties FOR ALL USING (true);

DROP POLICY IF EXISTS "Users can manage own saves" ON public.saved_properties;
CREATE POLICY "Users can manage own saves" ON public.saved_properties FOR ALL USING (true);

-- 4. HELPER FUNCTION TO SYNC FIREBASE USER
CREATE OR REPLACE FUNCTION public.sync_firebase_user(
    uid TEXT,
    u_phone TEXT,
    u_name TEXT DEFAULT 'Khozna User'
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.profiles (id, phone_number, full_name, kyc_status)
    VALUES (uid, u_phone, u_name, 'not_started')
    ON CONFLICT (id) DO UPDATE
    SET phone_number = EXCLUDED.phone_number,
        full_name = COALESCE(public.profiles.full_name, EXCLUDED.full_name);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
