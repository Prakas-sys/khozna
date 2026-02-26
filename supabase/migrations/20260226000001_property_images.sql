-- Create property_images table
CREATE TABLE IF NOT EXISTS public.property_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.property_images;

-- Enable RLS
ALTER TABLE public.property_images ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Property images are viewable by everyone" ON public.property_images FOR SELECT USING (true);
CREATE POLICY "Owners can manage their property images" ON public.property_images FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.properties 
        WHERE properties.id = property_images.property_id 
        AND properties.owner_id = auth.uid()
    )
);
