---
name: khozna_design
description: Apply Khozna's complete design system to any screen or widget. Use this when the user asks to redesign, polish, or apply branding to UI. Covers colors, typography, glassmorphism, animations, and micro-interactions.
---

# 🎨 Khozna Design System — Full Brand Guide

## When to Use
Use this skill whenever the user says:
- "Make this look better / premium"
- "Apply Khozna branding"
- "Add glassmorphism / animations"
- "Polish the UI"
- "It looks basic, fix it"

## Step 1 — Read the Screen
Read the target file fully before touching anything.

## Step 2 — Apply the Complete Design System

### 🎨 Color Palette
```dart
// PRIMARY
const Color kPrimary = Color(0xFF00A3E1);       // Khozna Cyan — CTA buttons, accents
const Color kPrimaryLight = Color(0xFFE0F5FF);  // Light cyan — backgrounds, chips

// NEUTRALS
const Color kBgWhite = Color(0xFFFFFFFF);
const Color kBgLight = Color(0xFFF8F9FA);
const Color kTextDark = Color(0xFF1A1A2E);
const Color kTextMid = Color(0xFF6B7280);
const Color kTextLight = Color(0xFF9CA3AF);

// SEMANTIC
const Color kSuccess = Color(0xFF10B981);
const Color kError = Color(0xFFEF4444);
const Color kWarning = Color(0xFFF59E0B);

// DARK (for cards, overlays)
const Color kDarkCard = Color(0xFF1E293B);
const Color kOverlay = Color(0x80000000);  // 50% black
```

### 🔤 Typography
```dart
// HEADINGS — Playfair Display
GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: kTextDark)
GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600, color: kTextDark)

// BODY / UI — Outfit
GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: kTextDark)  // Body
GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: kTextMid)   // Secondary
GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: kTextLight) // Caption
GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: kPrimary)   // CTA label
```

### ✨ Glassmorphism Card
```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: Colors.white.withOpacity(0.15),
    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Padding(padding: const EdgeInsets.all(16), child: /* content */),
    ),
  ),
)
// Required import: import 'dart:ui';
```

### 🃏 Standard Card
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
  ),
  child: /* content */,
)
```

### 🔘 Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF00A3E1),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  ),
  onPressed: () {},
  child: Text('Button', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
)
```

### ⌨️ Text Field
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Hint...',
    hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
    filled: true,
    fillColor: const Color(0xFFF8F9FA),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A3E1), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
)
```

### 💫 Micro-Animations

#### Fade + Slide In
```dart
// Wrap widget in AnimatedOpacity + AnimatedSlide or use TweenAnimationBuilder
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: 1),
  duration: const Duration(milliseconds: 400),
  builder: (context, value, child) => Opacity(
    opacity: value,
    child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
  ),
  child: /* your widget */,
)
```

#### Scale on Tap (Bouncy Button)
```dart
GestureDetector(
  onTapDown: (_) => setState(() => _isPressed = true),
  onTapUp: (_) => setState(() => _isPressed = false),
  onTapCancel: () => setState(() => _isPressed = false),
  child: AnimatedScale(
    scale: _isPressed ? 0.95 : 1.0,
    duration: const Duration(milliseconds: 100),
    child: /* your tappable widget */,
  ),
)
```

### 📳 Haptics
```dart
import 'package:flutter/services.dart';

HapticFeedback.lightImpact();   // Taps, selections
HapticFeedback.mediumImpact();  // Likes, confirmations
HapticFeedback.heavyImpact();   // Critical actions, errors
```

### 🏷️ Status Badge / Chip
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: const Color(0xFFE0F5FF),
    borderRadius: BorderRadius.circular(100),
  ),
  child: Text('Verified', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF00A3E1), fontWeight: FontWeight.w600)),
)
```

## Step 3 — The 60-30-10 Rule
For dark/reels style screens:
- **60%** — Dark base (`#1A1A2E` or `#000000`)
- **30%** — Secondary (`#FFFFFF` text, cards)
- **10%** — Accent (`#00A3E1` — icons, buttons, highlights)

## Step 4 — Checklist Before Done
- [ ] All fonts use `GoogleFonts.outfit()` or `GoogleFonts.playfairDisplay()`
- [ ] No hardcoded colors outside the palette
- [ ] All cards have border radius + shadow
- [ ] Loading states use cyan spinner
- [ ] Buttons have haptic feedback
- [ ] Sensitive screens have `SecurityUtils.setSecure(true)`
