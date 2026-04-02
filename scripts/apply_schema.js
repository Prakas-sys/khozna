const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres.qjpeablwokiuhfaopdbi:Khozna%40Success%23@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres',
  ssl: {
    rejectUnauthorized: false
  }
});

async function run() {
  try {
    await client.connect();
    console.log('Connected to Supabase PostgreSQL!');

    const sql = `
      -- 1. PROFILES TABLE
      CREATE TABLE IF NOT EXISTS public.profiles (
          id TEXT PRIMARY KEY,
          full_name TEXT,
          phone_number TEXT UNIQUE,
          email TEXT,
          avatar_url TEXT,
          kyc_status TEXT DEFAULT 'not_started',
          is_owner BOOLEAN DEFAULT false,
          fcm_token TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
      );

      -- 2. PROPERTIES TABLE
      CREATE TABLE IF NOT EXISTS public.properties (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          owner_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
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
          status TEXT DEFAULT 'available',
          latitude DOUBLE PRECISION,
          longitude DOUBLE PRECISION,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
      );

      -- 3. SAVED PROPERTIES
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
          status TEXT DEFAULT 'pending',
          rejection_reason TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
      );

      -- 5. NOTIFICATIONS
      CREATE TABLE IF NOT EXISTS public.notifications (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT DEFAULT 'general',
          is_read BOOLEAN DEFAULT false,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
      );

      -- 6. CHATS
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

      -- 7. MESSAGES
      CREATE TABLE IF NOT EXISTS public.messages (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE NOT NULL,
          sender_id TEXT REFERENCES public.profiles(id) NOT NULL,
          content TEXT NOT NULL,
          is_read BOOLEAN DEFAULT false,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
      );

      -- RLS
      ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
      ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
      ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;
      ALTER TABLE public.kyc_verifications ENABLE ROW LEVEL SECURITY;
      ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
      ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
      ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

      DROP POLICY IF EXISTS "Allow all access profiles" ON public.profiles;
      CREATE POLICY "Allow all access profiles" ON public.profiles FOR ALL USING (true);
      
      DROP POLICY IF EXISTS "Allow all access properties" ON public.properties;
      CREATE POLICY "Allow all access properties" ON public.properties FOR ALL USING (true);
      
      DROP POLICY IF EXISTS "Allow all access saved" ON public.saved_properties;
      CREATE POLICY "Allow all access saved" ON public.saved_properties FOR ALL USING (true);
      
      DROP POLICY IF EXISTS "Allow all access kyc" ON public.kyc_verifications;
      CREATE POLICY "Allow all access kyc" ON public.kyc_verifications FOR ALL USING (true);
      
      DROP POLICY IF EXISTS "Allow all access notif" ON public.notifications;
      CREATE POLICY "Allow all access notif" ON public.notifications FOR ALL USING (true);
      
      DROP POLICY IF EXISTS "Allow all access chats" ON public.chats;
      CREATE POLICY "Allow all access chats" ON public.chats FOR ALL USING (true);
      
      DROP POLICY IF EXISTS "Allow all access msgs" ON public.messages;
      CREATE POLICY "Allow all access msgs" ON public.messages FOR ALL USING (true);

      -- Sync function
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
    `;

    await client.query(sql);
    console.log('--- ALL TABLES CREATED SUCCESSFULLY ---');
    console.log('--- SYNC FUNCTION CREATED SUCCESSFULLY ---');
    console.log('--- RLS POLICIES APPLIED ---');

  } catch (err) {
    console.error('Error executing query:', err);
    if (err.stack) console.error(err.stack);
  } finally {
    await client.end();
  }
}

run();
