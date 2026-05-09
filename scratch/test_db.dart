import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('YOUR_URL', 'YOUR_KEY');
  try {
    final response = await supabase.from('messages').select().limit(1);
    print(response);
  } catch (e) {
    print('Error: $e');
  }
}
