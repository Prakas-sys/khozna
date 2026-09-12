-- =====================================================================
-- KHOZNA: Add is_suspended column to profiles
-- Run in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/qjpeablwokiuhfaopdbi/sql/new
-- =====================================================================

-- 1. Add is_suspended column (defaults to false = active)
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN NOT NULL DEFAULT false;

-- 2. Index for fast filtering
CREATE INDEX IF NOT EXISTS idx_profiles_is_suspended ON profiles(is_suspended);

-- 3. Allow admin dashboard to update this field (RLS must permit it)
--    If profiles table has RLS enabled with restrictive policies, add this:
DROP POLICY IF EXISTS "Allow admin suspend" ON profiles;
CREATE POLICY "Allow admin suspend" ON profiles
  FOR UPDATE USING (true) WITH CHECK (true);
