import 'dart:io';

// 🇳🇵 Khozna - Supabase Realtime Activator (Dart Edition)
void main() async {
  print('--- 🔗 Khozna Database Fix (Dart) ---');

  // We recommend the user runs the following SQL in their Supabase SQL Editor
  // if this script hits a local connectivity issue:
  const sql = '''
    BEGIN;
    -- 1. Enable Realtime for key tables
    ALTER PUBLICATION supabase_realtime ADD TABLE public.kyc_verifications;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_reports;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

    -- 2. Set Replica Identity for detailed payloads
    ALTER TABLE public.kyc_verifications REPLICA IDENTITY FULL;
    ALTER TABLE public.user_reports REPLICA IDENTITY FULL;
    ALTER TABLE public.notifications REPLICA IDENTITY FULL;
    COMMIT;
  ''';

  print('--- 📡 SQL Ready for Execution ---');
  print(sql);
  print('----------------------------------');

  // Since we are in a limited environment, we'll try to use 'psql' if available,
  // otherwise we'll ask the user to paste this into their Dashboard.
  try {
    final result = await Process.run('psql', [
      '--url',
      'postgresql://postgres.qjpeablwokiuhfaopdbi:Khozna%40Success%23@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres',
      '-c',
      sql,
    ]);

    if (result.exitCode == 0) {
      print('--- ✅ Realtime enrollment complete via PSQL! ---');
    } else {
      print(
        '--- ⚠️ Please paste the SQL above into your Supabase Dashboard SQL Editor for the FINAL fix. ---',
      );
    }
  } catch (e) {
    print('--- ⚠️ psql not found. Manual step required! ---');
    print(
      '--- 💡 Action: Copy the SQL block above and run it in your Supabase SQL Editor. ---',
    );
  }
}
