-- KHOZNA.COM - Full Database Setup
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard/project/qjpeablwokiuhfaopdbi/sql)

-- 1. Create Properties Table
CREATE TABLE IF NOT EXISTS public.properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    location TEXT NOT NULL,
    price TEXT NOT NULL,
    bedrooms INTEGER DEFAULT 1,
    bathrooms INTEGER DEFAULT 1,
    area TEXT,
    floor TEXT,
    description TEXT,
    image_url TEXT,
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'booked', 'sold')),
    owner_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Saved Properties Table (The "Magic" Link)
CREATE TABLE IF NOT EXISTS public.saved_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, property_id)
);

-- 3. Create Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    type TEXT DEFAULT 'booking_alert',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Enable Real-time for these tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.properties;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- 5. Set up Row Level Security (RLS)
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
-- Properties: Anyone can view, only owners can edit
CREATE POLICY "Public Properties are viewable by everyone" ON public.properties FOR SELECT USING (true);
CREATE POLICY "Users can insert their own properties" ON public.properties FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Saved Properties: Users can only see/edit their own saves
CREATE POLICY "Users can view their own saved properties" ON public.saved_properties FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can save properties" ON public.saved_properties FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unsave properties" ON public.saved_properties FOR DELETE USING (auth.uid() = user_id);

-- Notifications: Users can only see their own notifications
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);

-- 7. THE MAGIC: Trigger to automatically notify users when a saved property is booked
CREATE OR REPLACE FUNCTION public.notify_on_booking()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status = 'available' AND NEW.status = 'booked') THEN
        INSERT INTO public.notifications (user_id, title, message)
        SELECT user_id, 'Property Booked! 🏠', 'A property you saved (' || NEW.title || ') has just been booked.'
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

-- 8. Add some Initial Demo Data
INSERT INTO public.properties (id, title, location, price, bedrooms, bathrooms, area, floor, description, image_url)
VALUES (
    '00000000-0000-0000-0000-000000000001', 
    'Single room for student', 
    'Baneshwar, Kathmandu', 
    'रू 8,000', 
    1, 1, '450', '3rd Floor', 
    'College area, quiet environment.',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'
) ON CONFLICT (id) DO NOTHING;
