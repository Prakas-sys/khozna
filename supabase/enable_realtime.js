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
    console.log('--- 🔗 Connected to Khozna Supabase (PostgreSQL) ---');

    const sql = `
      -- 1. Enable Realtime for key tables
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_publication_tables 
          WHERE pubname = 'supabase_realtime' 
          AND schemaname = 'public' 
          AND tablename = 'kyc_verifications'
        ) THEN
          ALTER PUBLICATION supabase_realtime ADD TABLE public.kyc_verifications;
        END IF;

        IF NOT EXISTS (
          SELECT 1 FROM pg_publication_tables 
          WHERE pubname = 'supabase_realtime' 
          AND schemaname = 'public' 
          AND tablename = 'user_reports'
        ) THEN
          ALTER PUBLICATION supabase_realtime ADD TABLE public.user_reports;
        END IF;

        IF NOT EXISTS (
          SELECT 1 FROM pg_publication_tables 
          WHERE pubname = 'supabase_realtime' 
          AND schemaname = 'public' 
          AND tablename = 'notifications'
        ) THEN
          ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
        END IF;
      END $$;

      -- 2. Set Replica Identity for detailed payloads
      ALTER TABLE public.kyc_verifications REPLICA IDENTITY FULL;
      ALTER TABLE public.user_reports REPLICA IDENTITY FULL;
      ALTER TABLE public.notifications REPLICA IDENTITY FULL;
    `;

    await client.query(sql);
    console.log('--- ✅ Realtime enrollment complete! ---');

  } catch (err) {
    console.error('--- ❌ Error:', err.message);
  } finally {
    await client.end();
    console.log('--- 🎉 Database fix complete! ---');
  }
}

run();
