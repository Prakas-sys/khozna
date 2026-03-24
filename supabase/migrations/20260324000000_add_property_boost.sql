-- ==========================================
-- KHOZNA.COM - BOOST PROMOTION SCHEMA UPDATE
-- ==========================================

-- 1. Modify Properties Table
ALTER TABLE public.properties 
ADD COLUMN IF NOT EXISTS is_boosted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS boost_tier TEXT DEFAULT 'none' CHECK (boost_tier IN ('none', 'boost_3d', 'boost_7d', 'top_highlight')),
ADD COLUMN IF NOT EXISTS boost_expires_at TIMESTAMP WITH TIME ZONE;

-- 2. Create Payments Table
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_method TEXT DEFAULT 'esewa' CHECK (payment_method IN ('esewa', 'khalti', 'imepay', 'nepalpay')),
    boost_tier_purchased TEXT NOT NULL,
    transaction_id TEXT,           -- eSewa/Khalti/IME receipt number submitted by owner
    receipt_url TEXT,              -- optional screenshot/proof upload URL
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for payments
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow owners to view own payments" ON public.payments FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Allow owners to insert payments" ON public.payments FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Allow update for callbacks" ON public.payments FOR UPDATE USING (true);
