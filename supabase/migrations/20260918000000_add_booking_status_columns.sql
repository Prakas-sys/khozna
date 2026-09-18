-- MIGRATION: 20260918000000_add_booking_status_columns.sql
-- Add auxiliary booking tracking columns to public.bookings if they don't exist

ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS booking_status TEXT,
ADD COLUMN IF NOT EXISTS payment_status TEXT,
ADD COLUMN IF NOT EXISTS payment_proof_url TEXT,
ADD COLUMN IF NOT EXISTS payment_reference TEXT,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS visit_confirmed BOOLEAN,
ADD COLUMN IF NOT EXISTS visit_liked BOOLEAN,
ADD COLUMN IF NOT EXISTS feedback_reason TEXT;
