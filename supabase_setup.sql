-- =======================================================
-- KHOZNA ADMIN DASHBOARD & PAYMENT MODERATION SETUP
-- Run this script in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/qjpeablwokiuhfaopdbi/sql/new
-- =======================================================

-- 1. Ensure payment_proof_url exists on bookings table
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_proof_url TEXT;

-- 2. Allow public/authenticated read, write, and delete access to payments & bookings
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow read payments" ON payments;
CREATE POLICY "Allow read payments" ON payments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow read bookings" ON bookings;
CREATE POLICY "Allow read bookings" ON bookings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow admin update payments" ON payments;
CREATE POLICY "Allow admin update payments" ON payments FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow admin update bookings" ON bookings;
CREATE POLICY "Allow admin update bookings" ON bookings FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow delete payments" ON payments;
CREATE POLICY "Allow delete payments" ON payments FOR DELETE USING (true);

DROP POLICY IF EXISTS "Allow delete bookings" ON bookings;
CREATE POLICY "Allow delete bookings" ON bookings FOR DELETE USING (true);

-- 3. Verify indexes
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_bookings_guest_id ON bookings(guest_id);
