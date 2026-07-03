# 🏠 Khozna — Nepal's Rental Platform

<p align="center">
  <img src="assets/images/original_logo.png" alt="Khozna Logo" width="130"/>
</p>

<p align="center">
  <b>Find. Rent. Own. — The modern, video-first way to discover properties in Nepal.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
  <img src="https://img.shields.io/badge/Firebase-Messaging-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
  <img src="https://img.shields.io/badge/Platform-Android-34A853?style=for-the-badge&logo=android&logoColor=white"/>
</p>

---

## 📱 About

**Khozna** (खोज्ना) means *"to search"* in Nepali. It's a full-stack Flutter mobile application that reimagines how people in Nepal find, list, and interact with properties — built with a modern, Airbnb-inspired experience.

Whether you're a renter looking for a flat in Kathmandu, a homeowner listing your property, or looking for verified listings with no middleman agent fees — Khozna delivers a premium, secure mobile experience.

---

## ✨ Core Features

### 🎬 Immersive Video Tours
- **Full-Screen Swipeable Property Tours** — Walkthrough rooms in high-definition vertical video, swiping through listings effortlessly.
- **Dynamic Property Stats Overlays** — Key data like price, location, landlord verification, and booking slots overlay cleanly onto the video without blocking constraints.

### 🏡 Smart Location & Finding
- **Interactive Map Search** — Locate houses, apartments, and rooms across Nepal using an integrated custom map (OpenStreetMap) with fast clustering.
- **AI-Powered Search & Voice Recs** — Use standard search queries or voice-based prompts to get recommendation listings powered by Llama 3.3.
- **Verified KYC Landmarks** — Mandated location binding for all listing accounts helps eliminate spam and fake listings.

### 💬 Seamless Handshake
- **Real-Time Landlord Chat** — Built-in secure messaging channel between owners and searchers.
- **Quick Reply Suggestions** — Select standard answers instantly using the Khozna Premium Aesthetic bubble bars.
- **Real-time Notifications** — Instant feedback badges and FCM push alerts keep you updated on bookings and messages.

---

## 🛠️ Software Stack

| Layer | System | Details |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x / Dart 3.x | Reactive UI, Custom HSL themes, Outfit/Inter typography |
| **Backend & Sync** | Supabase Backend | Real-time PostgreSQL, Secure DB triggers, and Supabase Auth |
| **Push Channel** | Firebase Cloud Messaging | Remote alerts and background communication |
| **Media Delivery** | Cloudinary | Delivery and on-the-fly optimization of listing images & video walkthroughs |
| **Map View** | OpenStreetMap (OSM) | Marker grids, routing, and location picking via `flutter_map` |
| **Intelligence** | Groq Cloud Console | LLM-based voice property searches |

---

## 🚀 Setting Up the Application

### 1. Clone the project
```bash
git clone https://github.com/YOUR_USERNAME/khozna.git
cd khozna
flutter pub get
```

### 2. Configure Local Environment Variables
Create a file named `.env` in the root of the project:
```env
# Supabase Connectivity
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Llama AI Orchestration
GROQ_API_KEY=your_groq_api_key

# Cloudinary CDN Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# Federated Login Credentials
GOOGLE_WEB_CLIENT_ID=your_google_client_id
```
*(Keep this file local; it is listed in `.gitignore` to avoid exposing credentials)*

### 3. Add App Configurations
- Add `google-services.json` setup for FCM into `android/app/`.

### 4. Run the Dev Build
```bash
flutter run
```

---

## 📂 Project Architecture

```
lib/
├── core/           # Universal constants, security utilities, Supabase client services, and themes
├── features/       # Feature-centric modules (Auth, Chat messages, Owner Profile, Property Listings)
├── screens/        # Main landing and nav wrapper templates
├── theme/          # HSL design tokens & system typography elements
├── utils/          # Formatting helpers and shared calculations
├── widgets/        # Standalone, globally reusable atoms
└── main.dart       # App entry point
```

---

## 🤝 Contribution Guidelines
This is a private startup endeavor. Contributions, redistributions, or forks are restricted at this time.

---

## 📄 License

All rights reserved © 2026 Khozna. This project is not open for redistribution.

---

## 👨‍💻 Built by

**Prakash** — Full-Stack Flutter Developer  
🇳🇵 Kathmandu, Nepal

<p align="center">Made with ❤️ for Nepal's real estate future</p>
