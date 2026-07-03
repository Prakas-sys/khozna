# 🎨 Khozna — Design System & UI Specification

This document defines the exact visual assets, theme parameters, typography, and interactive component schemes. Refer to this to build consistent, premium, Airbnb-inspired UIs.

---

## 🎨 Color Palette & Theme Tokens
We use a light, clean interface with a signature blue brand accent:
- **Brand / Accent Color**: `Color(0xFF00A3E1)` (Vibrant Custom Blue)
- **Primary Text**: `Color(0xFF1A1A1A)` (Charcoal/Dark Off-Black)
- **Secondary Text**: `Color(0xFF757575)` (Soft Grey)
- **Background**: `Colors.white`
- **Border / Divider Color**: `Colors.grey[300]` (or `0xFFE0E0E0`)

Theme implementation can be accessed globally via standard theme fields in Flutter:
- Button themes: `ElevatedButtonTheme` (defaults to pill shape, brand blue background, white text).
- Input field decors: `InputDecorationTheme` (rounded, outlines in `grey[300]`, focused in brand blue).

---

## 🔠 Typography — Strict Rules
We use **exactly these fonts**. All are preloaded at boot in `main.dart`. Do not introduce any other font.

| Font | Usage |
| :--- | :--- |
| `GoogleFonts.plusJakartaSans` | All titles, card headlines, section headers |
| `GoogleFonts.inter` | Body text, prices, labels, phone input, hints, buttons, links, terms text |
| `GoogleFonts.mukta` | Nepali language subtitles, review tags, localised labels |
| `GoogleFonts.outfit` | Large stat numbers in Passport cards (e.g. review count, rating score) |
| `GoogleFonts.zenAntiqueSoft` | **Login screen only** — "Welcome Back To" and "KHOZNA" brand heading. Intentionally unique/premium feel. |

> ⚠️ **Never** use `poppins`, `montserrat`, `notoSans`, `firaCode`, or any other font unless it is added to the preload list in `main.dart` first.

---

## 📐 Shape & Geometry Rules
- **Pill Shape**: Inputs, buttons, tags, badges, and action triggers (like the Property Booking Button) must use fully rounded borders:
  ```dart
  BorderRadius.circular(50)
  ```
- **Cards**: Property cards and listings require rounded corners of `BorderRadius.circular(16)` or `BorderRadius.circular(12)` with light-grey borders and no heavy shadows (`elevation: 0`).

---

## 🖼️ Vector Icon Asset Directory (SVG)
To ensure smooth vector rendering, use `SvgPicture.asset()` with the following exact paths:

| Icon | Purpose | File Path |
| :--- | :--- | :--- |
| **Rupee (Rs.)** | Rent pricing representation | `assets/icons/vector of ruppes.svg` *(Note spelling format)* |
| **Wi-Fi** | Amenity check | `assets/icons/Vector wifi.svg` |
| **Kitchen** | Amenity check | `assets/icons/Vector kitchen.svg` |
| **Air Conditioning**| Amenity check | `assets/icons/Vector Ac.svg` |
| **Balcony** | Amenity check | `assets/icons/Vector balcony.svg` |
| **Water Supply** | Amenity check | `assets/icons/Vector water.svg` |
| **CCTV** | Amenity check | `assets/icons/Vector cctv.svg` |
| **Car Parking** | Amenity check | `assets/icons/Vector car.svg` |
| **Bike Parking** | Amenity check | `assets/icons/Vector bike.svg` |
| **Reels Screen** | Vertical video browsing icon | `assets/icons/Vector reel new okay.svg` |
| **Profile Screen**| Navigation and cards icon | `assets/icons/Vector profile.svg` |
| **Chat Message** | Communication action trigger | `assets/icons/Vectorproepty card meeasge.svg` |

---

## 📱 Layout Structures (The "Khozna Premium Aesthetic")

All components must align with what we call the **Khozna Premium Aesthetic**—defined by light backgrounds, high contrast text, and subtle margins.

### 1. Home Header & Search Bar
- **Header**: Horizontal padding `20`, vertical `8`. Profile & notification badge alerts wrapped in transparent Material InkWell containers.
- **Search Bar**: 
  - Height: `52`.
  - Border Radius: `BorderRadius.circular(30)`.
  - Border: `Color(0xFFD8DCE0)` with `0.5` width.
  - Shadow: Soft black offset: `BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, spreadRadius: 1, offset: Offset(1, 0))`.
  - End icon: Trailing microphone action inside an `AppTheme.brandColor` circle widget.

### 2. Conversational Message Bubbles (Asymmetric Corners)
To keep chat screens looking uniform and engaging:
- **Sender (Me)**:
  - Color: `AppTheme.brandColor` with white text.
  - Border Radius: `BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4))` (leaves bottom-right sharp).
  - No shadows.
- **Receiver (Other)**:
  - Color: `Colors.white` with `Color(0xFF1A1A1A)` charcoal text.
  - Border Radius: `BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16))` (leaves bottom-left sharp).
  - Shadow: `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: Offset(0, 1))`.
  - Border: `Border.all(color: Colors.grey.shade200)`.

### 3. Quick Replies & Badges
- **Quick Reply Bar**: Horizontal scroll, spacing `16` margin, individual white pills with `BorderRadius.circular(16)` and border `Colors.grey.shade300`.
- **Badges**: Red `Color(0xFFFF0000)` badge bubble with white bold text (size `11`).

### 4. 2-Column Amenity Listing
When displaying amenities on the property detail screen, present them in a responsive, two-column column/row layout using standard SVGs:
```dart
Row(
  children: [
    Expanded(child: AmenityTile(iconPath: 'assets/icons/Vector wifi.svg', label: 'High-speed Wi-Fi')),
    Expanded(child: AmenityTile(iconPath: 'assets/icons/Vector water.svg', label: '24/7 Water')),
  ],
)
```

### 5. Video Reels Overlay
Keep video controls, details overlays (price with Rupee symbol, landlord details, and buttons) elevated within safe areas. Ensure the layout handles differing viewport aspects so nothing clips behind standard system status/navigation bars.
