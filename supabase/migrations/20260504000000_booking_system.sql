-- ==========================================
-- KHOZNA.COM - BOOKING SYSTEM MIGRATION (V2 - CLEAN START)
-- ==========================================

-- 0. CLEANUP OLD TABLES (0 rows detected in previous scan)
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.bookings CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;

-- 1. UPDATE PROPERTIES TABLE
ALTER TABLE public.properties 
ADD COLUMN IF NOT EXISTS price_night DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS price_month DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS cancellation_policy TEXT DEFAULT 'standard';

-- 2. BOOKINGS TABLE
CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    guest_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    owner_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    total_price DECIMAL NOT NULL,
    khozna_fee DECIMAL DEFAULT 0,
    payment_type TEXT CHECK (payment_type IN ('direct', 'khozna')),
    status TEXT DEFAULT 'pending_approval' 
    CHECK (status IN (
        'pending_approval', 
        'awaiting_payment', 
        'paid', 
        'confirmed', 
        'checked_in', 
        'completed', 
        'cancelled', 
        'disputed'
    )),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. PAYMENTS TABLE
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE NOT NULL,
    payer_id TEXT REFERENCES public.profiles(id) NOT NULL,
    amount DECIMAL NOT NULL,
    payment_method TEXT CHECK (payment_method IN ('esewa', 'khalti', 'bank_transfer', 'cash')),
    reference_id TEXT, -- eSewa Ref ID
    proof_image_url TEXT, -- For Direct Payment verification
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. PROPERTY AVAILABILITY (Calendar)
CREATE TABLE IF NOT EXISTS public.property_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    blocked_date DATE NOT NULL,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    reason TEXT DEFAULT 'booking',
    UNIQUE(property_id, blocked_date)
);

-- 5. REVIEWS (Post-Stay)
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE NOT NULL,
    reviewer_id TEXT REFERENCES public.profiles(id) NOT NULL,
    target_id TEXT REFERENCES public.profiles(id) NOT NULL, -- Can be property owner or guest
    property_id UUID REFERENCES public.properties(id) NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(booking_id, reviewer_id)
);

-- ==========================================
-- AUTOMATION: BLOCK DATES ON CONFIRMED BOOKING
-- ==========================================

CREATE OR REPLACE FUNCTION public.block_property_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status != 'confirmed')) THEN
        -- Insert a row for each date between check_in and check_out
        INSERT INTO public.property_availability (property_id, blocked_date, booking_id, reason)
        SELECT 
            NEW.property_id, 
            d::date, 
            NEW.id, 
            'booking'
        FROM generate_series(NEW.check_in, NEW.check_out - interval '1 day', interval '1 day') AS d
        ON CONFLICT (property_id, blocked_date) DO NOTHING;
    END IF;

    IF (NEW.status = 'cancelled' AND OLD.status = 'confirmed') THEN
        -- Remove blocked dates if cancelled
        DELETE FROM public.property_availability 
        WHERE booking_id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if trigger exists and drop if so
DROP TRIGGER IF EXISTS on_booking_status_change ON public.bookings;
CREATE TRIGGER on_booking_status_change
    AFTER UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.block_property_dates();

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Bookings: Guest can see their own, Owner can see their properties' bookings
CREATE POLICY "Users can view their own bookings" 
ON public.bookings FOR SELECT 
USING (auth.uid()::text = guest_id OR auth.uid()::text = owner_id);

CREATE POLICY "Guests can create bookings" 
ON public.bookings FOR INSERT 
WITH CHECK (auth.uid()::text = guest_id);

CREATE POLICY "Users can update their own bookings" 
ON public.bookings FOR UPDATE 
USING (auth.uid()::text = guest_id OR auth.uid()::text = owner_id);

-- Payments: Payer and Payee (Owner) can see
CREATE POLICY "View related payments" 
ON public.payments FOR SELECT 
USING (
    auth.uid()::text = payer_id OR 
    EXISTS (
        SELECT 1 FROM public.bookings 
        WHERE id = public.payments.booking_id AND owner_id = auth.uid()::text
    )
);

-- Availability: Everyone can see (to filter search)
CREATE POLICY "Public view availability" 
ON public.property_availability FOR SELECT 
USING (true);

-- Reviews: Public view, but only guest can create
CREATE POLICY "Public view reviews" 
ON public.reviews FOR SELECT 
USING (true);

CREATE POLICY "Guests can review completed stays" 
ON public.reviews FOR INSERT 
WITH CHECK (
    auth.uid()::text = reviewer_id AND 
    EXISTS (
        SELECT 1 FROM public.bookings 
        WHERE id = booking_id AND status = 'completed'
    )
);

-- ==========================================
-- REAL-TIME ENABLEMENT
-- ==========================================
-- Re-add to publication (ensure they are cleared first if necessary, but ALTER works)
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.reviews;
