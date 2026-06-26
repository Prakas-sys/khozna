const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres:Khozna%40Success%23@db.qjpeablwokiuhfaopdbi.supabase.co:5432/postgres',
  ssl: {
    rejectUnauthorized: false
  }
});

async function run() {
  try {
    await client.connect();
    const sql = `
      -- 1. CLEAN UP ORPHAN DATA (Vital step!)
      -- Delete chats that reference users who no longer exist
      DELETE FROM public.chats 
      WHERE user1_id NOT IN (SELECT id FROM public.profiles)
      OR user2_id NOT IN (SELECT id FROM public.profiles);

      -- Delete messages that reference users who no longer exist
      DELETE FROM public.messages 
      WHERE sender_id NOT IN (SELECT id FROM public.profiles);

      -- 2. Fix Chats table links
      ALTER TABLE public.chats 
      DROP CONSTRAINT IF EXISTS chats_user1_id_fkey,
      DROP CONSTRAINT IF EXISTS chats_user2_id_fkey,
      DROP CONSTRAINT IF EXISTS chats_participant_one_fkey,
      DROP CONSTRAINT IF EXISTS chats_participant_two_fkey;

      ALTER TABLE public.chats
      ADD CONSTRAINT chats_user1_id_fkey 
      FOREIGN KEY (user1_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
      ADD CONSTRAINT chats_user2_id_fkey 
      FOREIGN KEY (user2_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

      -- 3. Fix Messages table links
      ALTER TABLE public.messages
      DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

      ALTER TABLE public.messages
      ADD CONSTRAINT messages_sender_id_fkey 
      FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

      -- 4. Update the deletion function
      CREATE OR REPLACE FUNCTION public.delete_own_account()
      RETURNS void
      LANGUAGE plpgsql
      SECURITY DEFINER 
      SET search_path = public
      AS $$
      BEGIN
        IF auth.uid() IS NULL THEN
          RAISE EXCEPTION 'Not authenticated';
        END IF;

        DELETE FROM auth.users WHERE id = auth.uid();
      END;
      $$;

      GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
    `;

    await client.query(sql);
    console.log('--- FINAL ACCOUNT DELETION FIX APPLIED SUCCESSFULLY ---');

  } catch (err) {
    console.error('Error executing query:', err);
  } finally {
    await client.end();
  }
}

run();
