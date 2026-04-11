---
name: supabase_db
description: Design, create, and modify Khozna's Supabase database schema. Use this when the user asks to add a new table, column, RLS policy, or database feature. Covers migrations, RLS, edge functions, and Supabase service integration.
---

# 🗄️ Supabase DB Skill — Khozna Database Layer

## When to Use
Use this skill whenever the user says:
- "Add a new table for [X]"
- "Add a column to [table]"
- "Write a migration"
- "Set up RLS for [table]"
- "Add a Supabase edge function"

## Step 1 — Know the Current Schema
Read `docs/GEMINI.md` to see the current tables:
- `profiles` — User data (Firebase UID as PK)
- `properties` — Rental listings
- `saved_properties` — Favourites
- `kyc_verifications` — Identity records
- `notifications` — Alerts
- `chats` — Conversation threads
- `messages` — Chat messages

Also read `lib/utils/supabase_service.dart` to see what queries already exist.

## Step 2 — Supabase Project Info
- **Project ID:** `qjpeablwokiuhfaopdbi`
- **URL:** `https://qjpeablwokiuhfaopdbi.supabase.co`
- Use the `mcp_supabase_*` tools to interact LIVE with the database.

## Step 3 — Migration Rules

### Always use `apply_migration` for DDL
Use the `mcp_supabase_apply_migration` tool for any CREATE TABLE, ALTER TABLE, CREATE INDEX, etc.
Never use `execute_sql` for schema changes.

### Standard Table Template
```sql
CREATE TABLE IF NOT EXISTS public.table_name (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.table_name ENABLE ROW LEVEL SECURITY;

-- Index for user lookups
CREATE INDEX idx_table_name_user_id ON public.table_name(user_id);
```

### RLS Policy Templates
```sql
-- Users can only see their own data
CREATE POLICY "Users can view own data" ON public.table_name
  FOR SELECT USING (auth.uid()::text = user_id);

-- Users can insert their own data
CREATE POLICY "Users can insert own data" ON public.table_name
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Users can update their own data
CREATE POLICY "Users can update own data" ON public.table_name
  FOR UPDATE USING (auth.uid()::text = user_id);

-- Users can delete their own data
CREATE POLICY "Users can delete own data" ON public.table_name
  FOR DELETE USING (auth.uid()::text = user_id);

-- Public read (for listings, profiles)
CREATE POLICY "Anyone can view" ON public.table_name
  FOR SELECT USING (true);
```

## Step 4 — Flutter Service Integration

After creating DB schema, add corresponding methods to `lib/utils/supabase_service.dart`:

### Standard Fetch Pattern
```dart
Future<List<Map<String, dynamic>>> getTableItems({required String userId}) async {
  try {
    final response = await _supabase
        .from('table_name')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Error fetching table items: $e');
    return [];
  }
}
```

### Standard Insert Pattern
```dart
Future<bool> insertItem({required Map<String, dynamic> data}) async {
  try {
    await _supabase.from('table_name').insert(data);
    return true;
  } catch (e) {
    debugPrint('Error inserting item: $e');
    return false;
  }
}
```

### Standard Update Pattern
```dart
Future<bool> updateItem({required String id, required Map<String, dynamic> data}) async {
  try {
    await _supabase.from('table_name').update(data).eq('id', id);
    return true;
  } catch (e) {
    debugPrint('Error updating item: $e');
    return false;
  }
}
```

### Realtime Subscription Pattern
```dart
void subscribeToTable({required String userId, required Function(List<Map<String, dynamic>>) onUpdate}) {
  _supabase
    .from('table_name')
    .stream(primaryKey: ['id'])
    .eq('user_id', userId)
    .listen((data) => onUpdate(data));
}
```

## Step 5 — Security Checklist
After any schema change, run `mcp_supabase_get_advisors` to check:
- [ ] RLS is enabled on all new tables
- [ ] All policies are correct (no over-permissive policies)
- [ ] Indexes exist for frequently queried columns
- [ ] No sensitive data exposed without auth

## Step 6 — Update GEMINI.md
After schema changes, update `docs/GEMINI.md` to document the new table:
```markdown
- `table_name`: Description of what it stores.
```
