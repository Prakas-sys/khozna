# Khozna Design System

> Based 100% on actual code in `lib/core/theme/app_theme.dart` and codebase.

---

## Brand Colors

| Name            | Hex         | Usage                                  |
|-----------------|-------------|----------------------------------------|
| Brand / Primary | `#00A3E1`   | Buttons, links, verified badge, active states |
| Primary Text    | `#1A1A1A`   | Headlines, body text                   |
| Secondary Text  | `#757575`   | Subtitles, hints, captions             |
| Background      | `#FFFFFF`   | App scaffold background                |

---

## Typography

- **Base font**: `Outfit` (Google Fonts) — used for all base text via `outfitTextTheme()`
- **UI components**: `Inter` (Google Fonts) — used for buttons, labels, form fields, cards
- **Custom**: `Zen Antique Soft`, `Zen Antique` — available in `assets/fonts/`

| Style         | Font    | Size | Weight |
|---------------|---------|------|--------|
| Display Large | Outfit  | 32   | Bold   |
| Display Medium| Outfit  | 28   | Bold   |
| Title Large   | Outfit  | 20   | Bold   |
| Body Large    | Outfit  | 16   | Regular|
| Body Medium   | Outfit  | 14   | Regular|

---

## Buttons

### ElevatedButton (global theme)
- Background: `#00A3E1`
- Text: White
- Elevation: `0`
- Border radius: `50` (pill shape)
- Padding: `16px` vertical

### Book Now button (property_details_screen.dart)
- Height: `48`
- Border radius: `100` (full pill)
- Elevation: `0`
- `shadowColor: Colors.transparent`
- `overlayColor: white at 8% opacity` (subtle tap feedback only)
- Padding: `36px` horizontal

---

## Inputs (global theme)

- Fill: White
- Border radius: `50` (pill shape)
- Hint color: `Colors.grey[400]`, size 13
- Default border: `Colors.grey[300]`
- Focused border: `#00A3E1`

---

## AppBar (global theme)

- Background: White
- Elevation: `0`
- ScrolledUnderElevation: `0`
- Center title: `false`
- Icon color: `#1A1A1A`

---

## Avatars

### Default Avatar Assets (in `assets/images/`)

| File                    | Used for          |
|-------------------------|-------------------|
| `man avatar.jpeg`       | Default male avatar |
| `women avatar.jpeg`     | Default female avatar |

### `AppTheme.buildAvatarWidget()`

Priority order:
1. **Local asset path** (starts with `assets/`) → `AssetImage`
2. **Remote URL** (starts with `http://` or `https://`) → `CachedNetworkImageProvider`
3. **Fallback** → `getIllustrationAvatar(name)` → returns `man avatar.jpeg` or `women avatar.jpeg`

### `AppTheme.getIllustrationAvatar(seed)`

Returns `women avatar.jpeg` if name contains any of:
`mrs`, `ms`, `miss`, `girl`, `woman`, `female`, `lady`, `sita`, `maya`, `pooja`, `rita`, `gita`, `anita`, `sunita`

Otherwise returns `man avatar.jpeg`.

### Edit Profile — Avatar Selector

Two chips shown below the profile photo:
- `👨 Man Avatar` → sets `assets/images/man avatar.jpeg`
- `👩 Woman Avatar` → sets `assets/images/women avatar.jpeg`

Selected chip: `#00A3E1` background, white text. Unselected: `Colors.grey[100]`.

---

## Identity & Trust (KYC) — 3 States

| State      | Badge Color  | Icon                      | Label         |
|------------|--------------|---------------------------|---------------|
| `verified` | `#00A3E1`    | `verified_rounded`        | Verified      |
| `pending`  | `#F59E0B`    | `hourglass_top_rounded`   | Under Review  |
| other      | `#C13511`    | `info_outline_rounded`    | Not Verified  |

### Rules (enforced in code)
- `_updateLocation()` saves GPS coords only — **never sets `kyc_status`**
- `kyc_status: 'verified'` is only set by admin after full document review
- `kyc_status: 'pending'` is set when user submits KYC documents via `KycScreen`
- Verified badge (`Icons.verified_rounded`, `#00A3E1`) in profile header only shows when `kycStatus == 'verified'`

---

## Image Assets (`assets/images/`)

| File                            | Purpose                       |
|---------------------------------|-------------------------------|
| `logo 2.png`                    | App launcher icon             |
| `splash_logo.png`               | Splash screen                 |
| `man avatar.jpeg`               | Default male avatar           |
| `women avatar.jpeg`             | Default female avatar         |
| `esewa.webp`                    | eSewa payment logo            |
| `khalti.png`                    | Khalti payment logo           |
| `Hotel.png`                     | Property category             |
| `Room New.png`                  | Property category             |
| `flat (2).png`                  | Property category             |
| `cottage (2).png`               | Property category             |
| `tiny house.png`                | Property category             |
| `other image.png`               | Property category             |
| `Map view.png`                  | Map UI reference              |
| `Property type screen.png`      | UI reference                  |

---

## Verification Flow

```
User fills KycScreen (name, phone, citizenship docs, selfie, location)
        ↓
kyc_status = 'pending'   [set in profiles table]
        ↓
Admin reviews in Supabase dashboard
        ↓
kyc_status = 'verified'  [set manually by admin]
        ↓
Verified badge appears in ProfileHeader + Edit Profile
```
