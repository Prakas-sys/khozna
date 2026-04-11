---
name: flutter_feature
description: Scaffold a new Flutter screen or feature following Khozna's exact code patterns, brand identity, and architecture. Use this whenever the user asks to add a new screen, page, or feature to the app.
---

# 🏗️ Flutter Feature Scaffold — Khozna Style

## When to Use
Use this skill whenever the user says:
- "Add a new screen"
- "Build a [X] feature"
- "Create a page for [X]"

## Step 1 — Understand the Feature
- Read `docs/PRD.md` to understand Khozna's vision and design principles.
- Read `docs/GEMINI.md` for tech stack, DB schema, and infrastructure details.
- Ask the user if unclear: What does this screen DO? Who sees it (owner/tenant/admin)?

## Step 2 — Read Reference Files
Before writing ANY code, read these files for patterns:
- `lib/screens/home_screen.dart` — Standard screen structure
- `lib/screens/property_details_screen.dart` — Complex screen with data fetching
- `lib/utils/supabase_service.dart` — How to call the backend
- `lib/widgets/property_card.dart` — Component pattern

## Step 3 — Follow Khozna Code Rules
All new screens MUST follow these rules:

### Architecture Pattern
```dart
class XxxScreen extends StatefulWidget {
  const XxxScreen({super.key});
  @override
  State<XxxScreen> createState() => _XxxScreenState();
}

class _XxxScreenState extends State<XxxScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // fetch from supabase
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

### Brand Rules (NEVER BREAK)
- **Primary Color:** `Color(0xFF00A3E1)` (Khozna Cyan)
- **Background:** `Colors.white` or `Color(0xFFF8F9FA)`
- **Font:** `GoogleFonts.outfit()` for body, `GoogleFonts.playfairDisplay()` for headings
- **Border Radius:** `BorderRadius.circular(16)` for cards, `BorderRadius.circular(12)` for buttons
- **Elevation/Shadow:** `BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)`
- **Screen Security:** Add `SecurityUtils.setSecure(true/false)` in `initState` for sensitive screens

### Navigation Pattern
```dart
// Push to screen
Navigator.push(context, MaterialPageRoute(builder: (_) => const XxxScreen()));

// Pop back
Navigator.pop(context);
```

### Loading State Pattern
```dart
if (_isLoading) {
  return const Center(child: CircularProgressIndicator(color: Color(0xFF00A3E1)));
}
```

### AppBar Pattern
```dart
AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  title: Text('Title', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.black87)),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
    onPressed: () => Navigator.pop(context),
  ),
)
```

## Step 4 — Create the Files
1. Create `lib/screens/xxx_screen.dart`
2. If new Supabase methods are needed, add them to `lib/utils/supabase_service.dart`
3. If reusable widget needed, create `lib/widgets/xxx_widget.dart`
4. Register navigation in `lib/screens/main_screen.dart` if it's a tab screen

## Step 5 — Update GSD Log
After completing, append to `docs/GSD.md`:
```
- [x] New Feature: [Feature Name] — [brief description] (Date: YYYY-MM-DD)
```
And append to `docs/progress.txt`:
```
## [DATE] [Feature Name] (COMPLETE)
- [x] Created xxx_screen.dart with [X, Y, Z] functionality
```
