---
name: khozna_design
description: Apply Khozna's complete design system, typography, and brand identity to any screen or widget. Use this when redesigning, polishing, or adding new features to ensure they match the Khozna "Platinum" platform standard.
---

# 🎨 Khozna Design System & Brand Guide

## 🏢 What is Khozna? (Company Core)
Khozna is Nepal's next-generation, premium real estate and rental platform. 
**Mission:** "Find your Next Home. No middleman."
**Key Differentiators:** Social-media style Property Reels, AI-driven search/chat, and strict KYC verification for high-trust "Verified Listings."

## When to Use
Use this skill whenever the user says:
- "Make this look better / premium"
- "Apply Khozna branding"
- "Match the home screen / real app style"
- "Polish the UI"

## Step 1 — Apply the Complete Design System

### 🎨 Color Palette
```dart
// PRIMARY BRAND
const Color kPrimary = Color(0xFF00A3E1);       // Khozna Cyan — Icons, CTAs, Mic Button
const Color kPrimaryLight = Color(0xFFE0F5FF);  // Light cyan — backgrounds, chips

// NEUTRALS & TEXT
const Color kBgWhite = Colors.white;
const Color kBgLight = Color(0xFFF8F9FA);       // Inputs, soft backgrounds
const Color kTextDark = Color(0xFF1A1A2E);      // Primary Headers
const Color kTextMid = Color(0xFF6B7280);       // "Airbnb Grey" for descriptions
const Color kDarkCard = Color(0xFF1E293B);

// SEMANTIC & ALERTS
const Color kSuccess = Color(0xFF00C853);       // Verified Green
const Color kAlertBadge = Color(0xFFFF0000);    // Pure Red for notification badges
```

### 🔤 Typography (Multi-Font Strategy)
Do NOT use Playfair Display. Use the following strict hierarchy:
```dart
// HEADINGS — Plus Jakarta Sans (Massive, bold, tightly spaced)
GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: Colors.black)
GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.0, color: kTextDark)

// UI LABELS & BADGES — Inter (Clean, readable system text)
GoogleFonts.inter(fontSize: 16, color: kTextMid)
GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white) // Badges

// BODY / GLOBAL FALLBACK — Outfit
GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: kTextDark)
```

### ✨ Glassmorphism (Heavy Usage)
Used for Nav Bars, Image overlay headers, and floating buttons.
```dart
ClipRRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Standard blur
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85), // or Colors.black.withOpacity(0.8) for dark
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: /* content */,
    ),
  ),
)
```

### 🃏 Floating Property Carousel Image
Never stretch images edge-to-edge. Wrap them in a white border with a heavy shadow.
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: Colors.white, width: 6), // Thick white border
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 12)),
    ],
  ),
  child: ClipRRect(borderRadius: BorderRadius.circular(26), child: /* image */),
)
```

### 🔘 Primary Button & Inputs
```dart
// Pill-shaped everything
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF00A3E1),
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // Pill shape
  ),
  // ...
)
```

### 💫 Micro-Animations & Haptics
```dart
// Always add haptics to buttons and tabs
import 'package:flutter/services.dart';
HapticFeedback.lightImpact();   // Standard taps
HapticFeedback.mediumImpact();  // Refreshing, toggles
HapticFeedback.heavyImpact();   // KYC alerts, big success

// Bouncy scale for icons (Pseudo-stroke for active state in bottom nav)
AnimatedScale(
  scale: isSelected ? 1.15 : 1.0,
  duration: const Duration(milliseconds: 200),
  // ...
)
```

## Step 2 — Product Guidelines
1. **Bilingual:** Always mix English and Nepali for context (e.g., `"सुविधाहरू (Amenities)"`). Do NOT use Hindi.
2. **Density:** Keep major sections separated by aggressive padding (`SizedBox(height: 44)`) for a premium "uncrowded" feel, but keep internal card elements tight.
3. **No Middleman & Trust:** Always emphasize the "Verified Listing" tag in green (`#00C853`) and owner KYC.
4. **Offline First:** Design with skeleton loaders and offline fallbacks in mind.

## Step 3 — Checklist Before Done
- [ ] Headers use `Plus Jakarta Sans` (tight tracking, heavy weight).
- [ ] System text/badges use `Inter`.
- [ ] Brand Cyan (`#00A3E1`) is used for primary CTAs.
- [ ] Heavy use of pill shapes (`BorderRadius.circular(50)`) for buttons.
- [ ] Floating elements use `BackdropFilter` glassmorphism.
