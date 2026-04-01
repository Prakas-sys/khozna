import psycopg2
import sys

# 🇳🇵 Khozna - Supabase Backend Setup Script
# Decoded Credentials:
# User: postgres.qjpeablwokiuhfaopdbi
# Pass: Khozna@Success#
# Host: aws-0-ap-southeast-1.pooler.supabase.com

def setup_backend():
    print("--- 🔗 Connecting to Khozna Supabase (PostgreSQL) ---")
    try:
        conn = psycopg2.connect(
            dbname="postgres",
            user="postgres.qjpeablwokiuhfaopdbi",
            password="Khozna@Success#",
            host="aws-0-ap-southeast-1.pooler.supabase.com",
            port="6543",
            sslmode='require'
        )
        cur = conn.cursor()
        
        print("--- 🔨 Creating User Reports Table ---")
        sql = """
        -- 1. Create table
        CREATE TABLE IF NOT EXISTS public.user_reports (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            reported_user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
            reporter_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
            reason TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
        );

        -- 2. Enable RLS
        ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

        -- 3. Create Policies
        DROP POLICY IF EXISTS "Allow all access reports" ON public.user_reports;
        CREATE POLICY "Allow all access reports" ON public.user_reports FOR ALL USING (true);
        """
        
        cur.execute(sql)
        conn.commit()
        print("--- ✅ Table 'user_reports' created successfully! ---")
        
        # Verify tables
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
        tables = cur.fetchall()
        print(f"--- 📊 Current Public Tables: {[t[0] for t in tables]} ---")
        
        cur.close()
        conn.close()
        print("--- 🎉 Backend Setup Complete! ---")
        
    except Exception as e:
        print(f"--- ❌ Error: {e} ---")
        sys.exit(1)

if __name__ == "__main__":
    setup_backend()
