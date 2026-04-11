---
name: app_security
description: Harden the Khozna app against hackers and security threats. Covers screen capture prevention, root detection, API key security, input validation, network security, certificate pinning, token storage, and code obfuscation. Use whenever the user asks to secure the app, prevent hacking, or audit security.
---

# 🔐 Khozna App Security Skill — Full Anti-Hacker Hardening

## When to Use
Use this skill whenever the user says:
- "Secure the app from hackers"
- "Prevent hacking / data theft"
- "Security audit"
- "Someone can steal data"
- "Make it production safe"
- "Add certificate pinning"
- "Prevent reverse engineering"

---

## ✅ What's Already Protected in Khozna

Before adding security, check what exists:
- Read `lib/utils/security_utils.dart` — Screen shield, root detection, secure storage
- Check `docs/GSD.md` for past security missions already completed

Already done:
- ✅ Screen Shield (`FLAG_SECURE`) — blocks screenshots on Login/KYC
- ✅ Root/Jailbreak Detection via `safe_device`
- ✅ Encrypted storage via `flutter_secure_storage`
- ✅ API keys in `.env` (not hardcoded)
- ✅ Code obfuscation on release build (`--obfuscate`)

---

## 🛡️ Security Layers — Full Checklist

### LAYER 1 — Screen & Data Extraction Prevention

#### Screen Shield (Already Implemented)
```dart
// In any sensitive screen's initState:
import 'package:khozna/utils/security_utils.dart';

@override
void initState() {
  super.initState();
  SecurityUtils.setSecure(true); // BLOCKS screenshots + screen recording
}

@override
void dispose() {
  SecurityUtils.setSecure(false); // Re-enable after leaving screen
  super.dispose();
}
```
**Apply to:** Login, OTP, KYC, Profile/Edit, Payment (if added), Settings

#### Screens that NEED `setSecure(true)` — Audit List
Run this check when asked to audit:
```
lib/screens/login_screen.dart       ✅ Must have
lib/screens/verify_phone_screen.dart ✅ Must have
lib/screens/kyc_screen.dart         ✅ Must have
lib/screens/edit_profile_screen.dart ✅ Must have
lib/screens/register_screen.dart    ✅ Must have
lib/screens/settings_screen.dart    ⚠️ Should have
```

---

### LAYER 2 — Device Integrity Detection

#### Enhanced Root/Emulator Check (Upgrade for Production)
Add this to `security_utils.dart`:
```dart
/// Enhanced device check — blocks rooted AND emulator devices
static Future<SecurityStatus> getDeviceStatus() async {
  try {
    final bool isRooted = await SafeDevice.isJailBroken;
    final bool isRealDevice = await SafeDevice.isRealDevice;
    final bool isMockLocation = await SafeDevice.isMockLocation;

    if (isRooted) return SecurityStatus.rooted;
    if (!isRealDevice) return SecurityStatus.emulator;
    if (isMockLocation) return SecurityStatus.mockLocation;
    return SecurityStatus.safe;
  } catch (_) {
    return SecurityStatus.safe; // Fail open to avoid blocking real users
  }
}

enum SecurityStatus { safe, rooted, emulator, mockLocation }
```

#### Block at App Launch (in `main.dart` `_initApp`)
```dart
// Add BEFORE services init:
final status = await SecurityUtils.getDeviceStatus();
if (status == SecurityStatus.rooted) {
  // Show warning dialog and exit
  runApp(const _BlockedApp(reason: 'rooted'));
  return;
}
```

---

### LAYER 3 — API Key & Secret Security

#### Current Status Check
```dart
// GOOD — reading from .env:
url: dotenv.env['SUPABASE_URL'] ?? '',
anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',

// BAD — never do this:
url: 'https://abc.supabase.co',  // ❌ Exposed in APK
```

#### .env File Rules — NEVER Break
```
# .env file must be:
# 1. Listed in pubspec.yaml assets (to bundle with app)
# 2. Listed in .gitignore (NEVER commit to GitHub)
# 3. Only read via flutter_dotenv

SUPABASE_URL=https://qjpeablwokiuhfaopdbi.supabase.co
SUPABASE_ANON_KEY=your_key_here
CLOUDINARY_CLOUD_NAME=your_name_here
AI_API_KEY=your_key_here
```

#### Check .gitignore Has This
```
.env
*.env
/build/debug-symbols/
google-services.json  # Optional — already has its own security
```

---

### LAYER 4 — Input Validation & Injection Prevention

#### Never Trust User Input — Sanitize Before DB Calls
```dart
/// Add to SecurityUtils:
static String sanitizeInput(String input) {
  // Remove dangerous characters, trim whitespace
  return input
    .trim()
    .replaceAll(RegExp(r'[<>"\';\\]'), '') // Strip XSS/SQL chars
    .substring(0, input.length > 500 ? 500 : input.length); // Max length
}

static bool isValidPhone(String phone) {
  // Nepal phone: starts with 97 or 98, 10 digits
  return RegExp(r'^(97|98)\d{8}$').hasMatch(phone);
}

static bool isValidUrl(String url) {
  return Uri.tryParse(url)?.hasAbsolutePath ?? false;
}
```

#### Use in forms before submitting:
```dart
final cleanTitle = SecurityUtils.sanitizeInput(_titleController.text);
if (cleanTitle.isEmpty) { /* show error */ return; }
```

---

### LAYER 5 — Network & API Security

#### Supabase RLS (Row Level Security) — THE Most Important Layer
Every table MUST have RLS enabled. Users should ONLY see their own data.

**Audit command** — run via Supabase MCP tool:
```sql
-- Check which tables have RLS disabled (DANGEROUS):
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = false;
```

#### Rate Limiting (Add to Supabase Edge Functions)
For sensitive endpoints like OTP, login attempts:
```typescript
// In a Supabase Edge Function:
const RATE_LIMIT = 5; // Max 5 attempts per 15 minutes
const key = `rate_limit:${userIp}:login`;
// Check Redis/DB for attempt count before processing
```

#### Timeout on API Calls
```dart
// Wrap Supabase calls with timeout:
final response = await _supabase
    .from('properties')
    .select()
    .timeout(const Duration(seconds: 10)); // Never hang indefinitely
```

---

### LAYER 6 — Token & Session Security

#### Secure Token Storage Pattern
```dart
// NEVER use SharedPreferences for tokens — use SecurityUtils vault:
// ✅ Correct:
await SecurityUtils.writeSecurely('auth_token', token);
final token = await SecurityUtils.readSecurely('auth_token');

// ❌ Wrong:
SharedPreferences prefs = await SharedPreferences.getInstance();
prefs.setString('token', token); // Stored as plain text!
```

#### Session Timeout (Add to main.dart)
```dart
// Auto logout after inactivity (15 min for security):
Timer? _inactivityTimer;

void _resetInactivityTimer() {
  _inactivityTimer?.cancel();
  _inactivityTimer = Timer(const Duration(minutes: 15), _logoutUser);
}

void _logoutUser() {
  supabase.Supabase.instance.client.auth.signOut();
  // Navigate to LoginScreen
}
```

---

### LAYER 7 — Reverse Engineering Prevention

#### Release Build MUST Use Obfuscation
```bash
# From /build_release workflow — always use these flags:
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-symbols \
  --target-platform android-arm64

# What this does:
# --obfuscate           → Renames all classes/methods to gibberish (a.b.c)
# --split-debug-info    → Keeps readable symbols OFFLINE, not in APK
# --target-platform     → Only build for 64-bit (smaller, more secure)
```

#### Debug Logs — Strip from Production
```dart
// Replace all debugPrint with this pattern:
import 'package:flutter/foundation.dart';

// Only prints in debug mode, silent in release:
if (kDebugMode) {
  debugPrint('Some internal info: $data');
}

// NEVER log sensitive data even in debug:
// ❌ debugPrint('User token: $token');
// ❌ debugPrint('Password: $password');
```

---

### LAYER 8 — UI Security (Prevent Data Leaks)

#### Mask Sensitive Data in UI
```dart
// Phone number masking:
String maskPhone(String phone) {
  if (phone.length < 7) return phone;
  return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
  // Result: 981****890
}

// Email masking:
String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email;
  final name = parts[0];
  return '${name.substring(0, 2)}***@${parts[1]}';
}
```

#### Password Fields — Always Obscure
```dart
TextField(
  obscureText: true,
  obscuringCharacter: '●',
  // Never show passwords in plain text
)
```

---

## 🔍 Security Audit — How to Run

When asked to "audit security", do ALL of these steps:

1. **Screen Shields** — grep all screen files for `SecurityUtils.setSecure`
2. **Hardcoded Secrets** — search codebase for raw URLs, tokens, API keys
3. **RLS Check** — run the SQL audit query via Supabase MCP
4. **Input Validation** — check all TextFields / forms for sanitization
5. **Debug Logs** — search for `debugPrint` with sensitive data
6. **Supabase Advisors** — run `mcp_supabase_get_advisors(type: 'security')`

### Quick Grep Commands for Audit:
```bash
# Find hardcoded secrets:
grep -r "supabase.co" lib/ --include="*.dart"
grep -r "apiKey" lib/ --include="*.dart"
grep -rn "password" lib/ --include="*.dart"

# Find missing screen shields:
grep -rL "setSecure" lib/screens/ --include="*.dart"

# Find unprotected debugPrint:
grep -rn "debugPrint" lib/ --include="*.dart"
```

---

## 📋 Security Score Card

After any security work, report to user:

| Layer | Status | Priority |
|---|---|---|
| Screen Shield | ✅/❌ | CRITICAL |
| Root Detection | ✅/❌ | HIGH |
| API Keys in .env | ✅/❌ | CRITICAL |
| RLS Enabled | ✅/❌ | CRITICAL |
| Input Validation | ✅/❌ | HIGH |
| Obfuscated Build | ✅/❌ | HIGH |
| No Debug Logs in prod | ✅/❌ | MEDIUM |
| Token in Secure Storage | ✅/❌ | HIGH |
| Session Timeout | ✅/❌ | MEDIUM |

---

## ⚠️ Things That Will Get You Hacked (NEVER DO)

```dart
// ❌ Hardcoded keys
final url = 'https://qjpeablwokiuhfaopdbi.supabase.co';

// ❌ Plain SharedPreferences for tokens
prefs.setString('token', authToken);

// ❌ Logging sensitive data
debugPrint('User data: ${user.toJson()}');

// ❌ No input sanitization
await supabase.from('messages').insert({'content': userInput}); // SQL injection risk

// ❌ No screen security on OTP screen
// (OTP can be screen-recorded and stolen)

// ❌ Building release without obfuscation
flutter build apk --release  // APK can be decompiled!
```
