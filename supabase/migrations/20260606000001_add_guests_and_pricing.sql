-- MIGRATION: 20260606_add_guests_column.sql
-- Run this in your Supabase SQL Editor to fix the 'guests' column error.

ALTER TABLE public.properties 
ADD COLUMN IF NOT EXISTS guests INTEGER DEFAULT 1;

-- Also update the verification status if not present
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='properties' AND column_name='price_night') THEN
        ALTER TABLE public.properties ADD COLUMN price_night DECIMAL DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='properties' AND column_name='price_month') THEN
        ALTER TABLE public.properties ADD COLUMN price_month DECIMAL DEFAULT 0;
    END IF;
END $$;
