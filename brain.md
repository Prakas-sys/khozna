# 🧠 Khozna — Project Brain

## 📖 Overview
**Khozna** (*"to search"* in Nepali) is a premium, Airbnb-inspired, full-stack property discovery and listing platform for Nepal. The frontend is built with **Flutter**, and the backend services are powered by **Supabase** (database, realtime, and auth), **Firebase** (messaging & crash analytics), **Cloudinary** (media storage), and **Groq Cloud (Llama 3.3)** for AI-powered voice/text property search.

---

## 🚀 Setup & Environment Cheat-Sheet
### Prerequisites
- Flutter SDK `^3.11.0`
- Dart SDK `^3.11.0`
- Android Studio / VS Code + Emulators

### Environment Variables (`.env`)
The app uses `flutter_dotenv` to load configurations. Ensure your local `.env` contains:
```env
# Supabase Configuration
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# AI Search Configuration (Groq)
GROQ_API_KEY=your_groq_api_key

# Cloudinary Media Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# Authentication
GOOGLE_WEB_CLIENT_ID=your_google_client_id
```

### Firebase Integration
Place the latest `google-services.json` in `android/app/` to enable push notifications and analytics.

---

## 📂 Real Project Structure
We follow a feature-centric and clean architecture pattern:
```
KHOZNA.COM/
├── assets/                 # App assets (images/ icons/)
│   ├── icons/              # SVG vectors (e.g. rupee icon, amenities)
│   └── images/             # Brand logos & splash screens
├── lib/                    # Main Flutter application
│   ├── core/               # Core configurations, services, global network clients
│   ├── features/           # Modular features (auth, chat, profile, properties)
│   ├── screens/            # Top-level screen layouts & flow managers
│   ├── theme/              # Typography, HSL color palette, dark mode styles
│   ├── utils/              # Help helpers & formatters
│   ├── widgets/            # Globally reusable UI atoms/molecules
│   └── main.dart           # App bootstrapper
├── supabase/               # Supabase migrations, edge functions, schemas
└── test/                   # Widget & unit tests
```

---

## 🛠️ Tech Stack & Key Libraries
- **Backend/Auth/Db**: `supabase_flutter` — Database CRUD, realtime subscriptions, and authentication.
- **Push Notifications**: `firebase_messaging` & `flutter_local_notifications` — Cloud notifications and background channel alerts.
- **Maps Integration**: `flutter_map` (OpenStreetMap) + `latlong2` + `flutter_map_marker_cluster` — Precise location picking and map pins.
- **Media Uploads**: `cloudinary_flutter` — Uploading/delivering optimized home listings images & reels videos.
- **Reels Engine**: `video_player` + `video_compress` — Swipable vertical video layout.
- **Secure Storage**: `flutter_secure_storage` & `shared_preferences`.

---

## 📋 Common Developer Commands
| Task | Command |
| :--- | :--- |
| **Install packages** | `flutter pub get` |
| **Run app (Android)** | `flutter run` |
| **Run app (Web)** | `flutter run -d chrome` |
| **Generate Splash Screen** | `flutter pub run flutter_native_splash:create` |
| **Regenerate App Icons** | `flutter pub run flutter_launcher_icons:main` |
| **Analyze code quality** | `flutter analyze` |
| **Format all Dart files** | `flutter format .` |

---

## 🎨 Design System & UI Policies
1. **Airbnb Aesthetic**: Curate vibrant, premium dark mode styling and tailored HSL gradient backdrops. Avoid standard raw colors (like pure green or blue).
2. **Typography**: Use Google Fonts (Inter, Roboto, or Outfit) consistently.
3. **No Badges/Price Suffixes**: Standardize price rendering directly with the custom Nepalese Rupee SVG vector instead of appending `/‑` or using raw text indicators.
4. **Verified Flows**: Enforce mandatory KYC location binding for landlords. Hide sensitive details or labels like "Lives in" on profile cards.

---

## ✅ Ongoing Tasks & Iterative Roadmap
- [x] Standardize property pricing widgets.
- [x] Integrate custom Rupee SVG icon.
- [x] Add real-time top notification alerts.
- [x] Implement Reels video viewport constraints to keep metadata overlays visible.
- [ ] Add compact pill-shaped booking trigger on property pages.
- [ ] Convert amenities listings to a responsive 2-column icon grid.
- [ ] Enforce geolocation lock during landlord onboarding.
