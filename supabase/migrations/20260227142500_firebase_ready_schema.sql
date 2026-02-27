-- ==========================================
-- KHOZNA.COM - COMPLETE FIREBASE-READY SCHEMA
-- ==========================================

-- 1. PROFILES TABLE (Firebase UID as TEXT)
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY, -- Firebase UID
    full_name TEXT,
    phone_number TEXT UNIQUE,
    email TEXT,
    avatar_url TEXT,
    kyc_status TEXT DEFAULT 'not_started' CHECK (kyc_status IN ('not_started', 'pending', 'verified', 'rejected')),
    is_owner BOOLEAN DEFAULT false,
    fcm_token TEXT, -- For Push Notifications
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. PROPERTIES TABLE
CREATE TABLE IF NOT EXISTS public.properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('Room', 'Flat', 'House', 'Land')),
    area_name TEXT NOT NULL,
    landmark TEXT,
    price DECIMAL NOT NULL,
    is_negotiable BOOLEAN DEFAULT true,
    bedrooms INTEGER DEFAULT 0,
    bathrooms INTEGER DEFAULT 0,
    sq_ft TEXT,
    floor TEXT,
    description TEXT,
    amenities TEXT[], 
    images TEXT[],    
    video_url TEXT,   
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'booked', 'sold', 'hidden')),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. SAVED PROPERTIES (Favorites)
CREATE TABLE IF NOT EXISTS public.saved_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, property_id)
);

-- 4. KYC VERIFICATIONS
CREATE TABLE IF NOT EXISTS public.kyc_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    citizenship_number TEXT NOT NULL,
    document_front_url TEXT,
    document_back_url TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'general' CHECK (type IN ('general', 'booking_alert', 'chat', 'kyc_update')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. CHATS & MESSAGES
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    participant_one TEXT REFERENCES public.profiles(id) NOT NULL,
    participant_two TEXT REFERENCES public.profiles(id) NOT NULL,
    last_message TEXT,
    last_message_time TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(participant_one, participant_two, property_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE NOT NULL,
    sender_id TEXT REFERENCES public.profiles(id) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==========================================
-- ENABLE REAL-TIME
-- ==========================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.properties;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all access" ON public.profiles FOR ALL USING (true);
CREATE POLICY "Allow all access" ON public.properties FOR ALL USING (true);
CREATE POLICY "Allow all access" ON public.saved_properties FOR ALL USING (true);
CREATE POLICY "Allow all access" ON public.kyc_verifications FOR ALL USING (true);
CREATE POLICY "Allow all access" ON public.notifications FOR ALL USING (true);
CREATE POLICY "Allow all access" ON public.chats FOR ALL USING (true);
CREATE POLICY "Allow all access" ON public.messages FOR ALL USING (true);

-- ==========================================
-- SYNC FUNCTION & TRIGGERS
-- ==========================================

-- A. Sync Firebase User (Called from Flutter)
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

-- B. Booking Notification Trigger
CREATE OR REPLACE FUNCTION public.notify_on_booking()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status = 'available' AND NEW.status = 'booked') THEN
        INSERT INTO public.notifications (user_id, title, message, type)
        SELECT user_id, 'Property Booked! 🏠', 'A property you saved (' || NEW.title || ') has just been booked.', 'booking_alert'
        FROM public.saved_properties
        WHERE property_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_property_booked
    AFTER UPDATE ON public.properties
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.notify_on_booking();
