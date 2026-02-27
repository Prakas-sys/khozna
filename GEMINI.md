# Khozna - Rental App Nepal 🇳🇵

## Project Overview
Khozna is a modern property rental platform tailored for the Nepal market, featuring direct owner-to-tenant communication, verified listings, and integrated security features.

## Technical Stack
- **Frontend:** Flutter (Dart)
- **Backend/Database:** Supabase
- **Authentication:** Firebase Auth (Phone OTP + Google Sign-In)
- **Media Storage:** Cloudinary
- **Package Name:** `com.khozna.khozna`

## Infrastructure Details
- **Supabase URL:** `https://qjpeablwokiuhfaopdbi.supabase.co`
- **Firebase Project ID:** `khozna-746e2`
- **Cloudinary Cloud Name:** `dqxqfcicx`

## Database Schema (Public)
The database is optimized for Firebase Auth synchronization using `TEXT` based IDs for user profiles.

### Primary Tables:
- `profiles`: User information synced from Firebase (using Firebase UID as Primary Key).
- `properties`: Rental listings (Room, Flat, House, Land).
- `saved_properties`: User favorites/bookmarks.
- `kyc_verifications`: Identity verification records.
- `notifications`: System and booking alerts.
- `chats`: Conversation threads between users/owners.
- `messages`: Individual chat messages.

## Security Standards
- **Screen Shield:** `SecurityUtils.setSecure(true)` used on sensitive screens (Login, OTP, KYC) to prevent screenshots/recordings.
- **Root/Jailbreak Detection:** Automated checks on app launch to ensure device integrity.
- **Auth Walls:** Critical actions (Search, Post Property, Profile, Messages) require an active Firebase session.

## Key Features
- **Phone OTP Verification:** Region-locked to Nepal (+977).
- **Verified Listings:** Integrated KYC workflow for property owners.
- **Real-time Notifications:** Powered by Supabase Realtime for instant booking and chat updates.
- **Persistent Login:** Seamless session management across app restarts.
