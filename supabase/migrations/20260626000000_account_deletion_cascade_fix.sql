-- Fix Chat and Message foreign keys to allow automatic account deletion
-- This script adds "ON DELETE CASCADE" to the missing links.

-- 1. Fix Chats table links
ALTER TABLE public.chats 
DROP CONSTRAINT IF EXISTS chats_participant_one_fkey,
DROP CONSTRAINT IF EXISTS chats_participant_two_fkey;

ALTER TABLE public.chats
ADD CONSTRAINT chats_participant_one_fkey 
FOREIGN KEY (participant_one) REFERENCES public.profiles(id) ON DELETE CASCADE,
ADD CONSTRAINT chats_participant_two_fkey 
FOREIGN KEY (participant_two) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 2. Fix Messages table links
ALTER TABLE public.messages
DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

ALTER TABLE public.messages
ADD CONSTRAINT messages_sender_id_fkey 
FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 3. Update the deletion function to be more robust
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER 
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- The cascades we just fixed will now allow this to work perfectly
  -- This will wipe: Profiles, Properties, Saves, KYC, Notifications, Chats, and Messages
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;
