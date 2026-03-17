-- ==========================================
-- KHOZNA.COM - COMPREHENSIVE DATABASE SETUP
-- ==========================================
-- This script sets up the entire backend for Khozna including:
-- Profiles, Properties, Saved Listings, Notifications, 
-- Chats, and KYC Verifications.

-- 1. PROFILES TABLE
-- Extends the built-in auth.users table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    phone_number TEXT UNIQUE,
    email TEXT,
    avatar_url TEXT,
    kyc_status TEXT DEFAULT 'not_started' CHECK (kyc_status IN ('not_started', 'pending', 'verified', 'rejected')),
    is_owner BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. PROPERTIES TABLE
CREATE TABLE IF NOT EXISTS public.properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
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
    amenities TEXT[], -- Array of strings: ['Water', 'Wifi', etc.]
    images TEXT[],    -- Array of image URLs
    video_url TEXT,   -- For Reels
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'booked', 'sold', 'hidden')),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. SAVED PROPERTIES (Favorites)
CREATE TABLE IF NOT EXISTS public.saved_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, property_id)
);

-- 4. KYC VERIFICATIONS
CREATE TABLE IF NOT EXISTS public.kyc_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
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
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
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
    participant_one UUID REFERENCES public.profiles(id) NOT NULL,
    participant_two UUID REFERENCES public.profiles(id) NOT NULL,
    last_message TEXT,
    last_message_time TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(participant_one, participant_two, property_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES public.profiles(id) NOT NULL,
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

-- 1. Profiles: Users can read all (to see owners), but only update their own
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. Properties: Anyone can view available, only owners can manage
CREATE POLICY "Anyone can view available properties" ON public.properties FOR SELECT USING (status != 'hidden');
CREATE POLICY "Owners can manage their properties" ON public.properties ALL USING (auth.uid() = owner_id);

-- 3. Saved Properties: Private per user
CREATE POLICY "Users can manage own saves" ON public.saved_properties ALL USING (auth.uid() = user_id);

-- 4. KYC: Private per user
CREATE POLICY "Users can view/submit own KYC" ON public.kyc_verifications ALL USING (auth.uid() = user_id);

-- 5. Notifications: Private per user
CREATE POLICY "Users can view/manage own notifications" ON public.notifications ALL USING (auth.uid() = user_id);

-- 6. Chats & Messages: Private to participants
CREATE POLICY "Users can see their own chats" ON public.chats FOR SELECT USING (auth.uid() = participant_one OR auth.uid() = participant_two);
CREATE POLICY "Users can see messages in their chats" ON public.messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.chats 
        WHERE chats.id = messages.chat_id 
        AND (chats.participant_one = auth.uid() OR chats.participant_two = auth.uid())
    )
);
CREATE POLICY "Users can send messages" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- ==========================================
-- FUNCTIONS & TRIGGERS (THE MAGIC)
-- ==========================================

-- A. Auto-create Profile on Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, phone_number, email)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.phone, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- B. Booking Notification (Notify users who saved the property)
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

-- C. Update last_message in Chat on new message
CREATE OR REPLACE FUNCTION public.update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.chats
    SET last_message = NEW.content,
        last_message_time = NEW.created_at
    WHERE id = NEW.chat_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_message
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.update_chat_last_message();
