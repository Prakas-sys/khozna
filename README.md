# 🏠 Khozna — Nepal's Rental Platform

<p align="center">
  <img src="assets/images/original_logo.png" alt="Khozna Logo" width="120"/>
</p>

<p align="center">
  <b>Find. Rent. Own. — The modern way to discover property in Nepal.</b>
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

*Khozna* means *"to search"* in Nepali. It's a full-stack Flutter mobile application that reimagines how people in Nepal find, list, and interact with properties — built with a modern, Airbnb-inspired experience.

Whether you're a tenant looking for a room, a landlord listing your property, or an investor exploring the market — Khozna has you covered.

---

## ✨ Features

### 🏡 Property Discovery
- **Reels-style property browsing** — swipe through properties like social media
- **Smart Map View** — explore listings on an interactive map with clustering
- **Advanced Search & Filters** — filter by price, location, amenities, and more
- **AI-powered search** — voice and text-based smart property recommendations

### 🔐 Authentication & Security
- Phone number + OTP login
- Google Sign-In
- KYC verification with mandatory location binding
- Secure storage with `flutter_secure_storage`
- Safe device detection

### 💬 Communication
- Real-time in-app chat between tenants and landlords
- Push notifications via Firebase Cloud Messaging
- In-app notifications system

### 🏠 Property Management
- Multi-image & video property listings
- Cloudinary media storage & optimization
- Amenities management
- Guest recommendations / voting system

### 👤 User Profiles
- Owner & tenant profiles
- Verification badges
- Activity history

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x / Dart 3.x |
| **Backend & DB** | Supabase (PostgreSQL + Realtime) |
| **Auth** | Supabase Auth + Google Sign-In |
| **Push Notifications** | Firebase Cloud Messaging |
| **Analytics & Crash** | Firebase Analytics + Crashlytics |
| **Media Storage** | Cloudinary |
| **Maps** | Flutter Map (OpenStreetMap) |
| **AI / LLM** | Groq (Llama 3.3) |
| **State Management** | Flutter built-in + Streams |
| **Local Storage** | Shared Preferences + Secure Storage |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.11.0`
- Dart SDK `^3.11.0`
- Android Studio / VS Code
- A Supabase project
- A Firebase project

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/khozna.git
cd khozna

# Install dependencies
flutter pub get
```

### Environment Setup

Create a `.env` file in the root directory:

```env
# Supabase
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# AI (Groq)
GROQ_API_KEY=your_groq_api_key

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# Google
GOOGLE_WEB_CLIENT_ID=your_google_client_id
```

> ⚠️ **Never commit your `.env` file.** It is listed in `.gitignore` for safety.

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app and download `google-services.json`
3. Place it in `android/app/`

### Run the App

```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── core/           # App-wide constants, configs, services
├── features/       # Feature modules (auth, chat, profile, property)
├── screens/        # Main screen compositions
├── theme/          # App theme & design tokens
├── utils/          # Helper functions & utilities
├── widgets/        # Reusable UI components
└── main.dart       # App entry point
```

---

## 📸 Screenshots

> Coming soon — app screenshots will be added here.

---

## 🤝 Contributing

This is a private startup project. Contributions are not open at this time.

---

## 📄 License

All rights reserved © 2026 Khozna. This project is not open for redistribution.

---

## 👨‍💻 Built by

**Prakash** — Full-Stack Flutter Developer  
🇳🇵 Kathmandu, Nepal

<p align="center">Made with ❤️ for Nepal's real estate future</p>
