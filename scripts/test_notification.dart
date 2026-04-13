import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  // Read .env manually
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String url = '';
  String key = '';
  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) url = line.split('=')[1];
    if (line.startsWith('SUPABASE_ANON_KEY=')) key = line.split('=')[1];
  }
  
  final supabase = SupabaseClient(url, key);
  
  try {
    final res = await supabase.from('notifications').select('*, sender:sender_id(full_name, avatar_url)');
    print('Fetched: ${res}');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
