-- 1. Create Reels Storage Bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('reels', 'reels', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage Policies for 'reels' bucket
-- Allow public access to read reels
CREATE POLICY "Public Access to Reels"
ON storage.objects FOR SELECT
USING ( bucket_id = 'reels' );

-- Allow authenticated users to upload reels
CREATE POLICY "Users can upload reels"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'reels' AND auth.role() = 'authenticated' );

-- 3. Create Reels Table in public schema
CREATE TABLE IF NOT EXISTS public.reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    video_url TEXT NOT NULL,
    caption TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.reels;

-- Enable RLS
ALTER TABLE public.reels ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Reels are viewable by everyone" ON public.reels FOR SELECT USING (true);
CREATE POLICY "Users can manage their own reels" ON public.reels FOR ALL USING (auth.uid() = user_id);
