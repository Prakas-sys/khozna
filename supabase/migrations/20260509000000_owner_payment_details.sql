-- Migration to add payment details to profiles

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS esewa_number TEXT,
ADD COLUMN IF NOT EXISTS khalti_number TEXT,
ADD COLUMN IF NOT EXISTS account_holder_name TEXT,
ADD COLUMN IF NOT EXISTS qr_code_url TEXT;
