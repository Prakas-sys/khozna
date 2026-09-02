---
name: system-health-engineering
description: Comprehensive engineering excellence skill for maintainability, memory management, payment escrow architecture, offline resilience, real-time sync, and long-term stability in the Khozna system.
---

# Khozna System Health & Payment Engineering Excellence Skill

This skill documents mandatory engineering guidelines, memory management patterns, and the complete **Payment & Escrow System Architecture** to ensure the Khozna platform remains bulletproof, audit-compliant, and fraud-resistant over long periods of continuous operation.

---

## 💳 1. Payment System Architecture & State Machine

The Khozna Escrow payment pipeline follows a strict, unidirectional state machine to guarantee zero double-spending, audit transparency, and owner trust.

```
[Guest Initiates Payment] 
         │
         ▼
[Payment Proof / Gateway Txn] ➔ Status: 'payment_submitted'
         │
         ▼ (Admin / System Verification)
[Khozna Escrow Vault]        ➔ Status: 'paid' / 'escrow_held' (Owner Notified)
         │
         ▼ (Guest Check-In Date)
[Check-In Confirmed]          ➔ Status: 'confirmed' / 'payout_ready'
         │
         ▼ (Disbursal to Owner eSewa/Khalti/Bank)
[Owner Payout Disbursed]     ➔ Status: 'payout_disbursed' (Receipt Generated)
```

---

## 🔒 2. Payment Engineering Rules & Security Protocols

### A. Idempotency & Double-Payment Guarding
* Every payment transaction MUST generate a unique deterministic reference code (`KHZ-XXXXXX`).
* The system MUST prevent submitting multiple active payments for the same `booking_id`.

### B. Payer Attribution Sanitization
* **Mandatory Terminology Rule**: The payer in notifications, receipts, and cards MUST ALWAYS be attributed to the **Guest** (e.g., *"Guest [Name] sent payment via Khozna Escrow"*).
* **Strict Blacklist**: The system MUST NEVER output *"Khozna app sent payment"*. "Khozna" is the escrow vault/platform, never the payer.

### C. Owner Payout Data Schema
Owners register their payout destination in `profiles`:
* `esewa_number` (Text - eSewa ID / Mobile)
* `khalti_number` (Text - Khalti ID)
* `account_holder_name` (Text - Bank Name & Account Number)

### D. Audit Logging
Every status transition to `payout_disbursed` MUST record:
1. `booking_id` & `property_id`
2. `amount` & `currency` ('NPR')
3. `owner_id` & `payout_target` (`esewa_number` / `khalti_number` / `account_holder_name`)
4. `disbursed_at` timestamp

---

## 🧠 3. Memory & Resource Lifecycle Management

1. **Controllers & Focus Nodes**:
   Every `TextEditingController`, `FocusNode`, and `AnimationController` declared in a `StatefulWidget` MUST be disposed inside `dispose()`.

2. **Realtime Subscriptions**:
   Supabase `RealtimeChannel` listeners MUST be unsubscribed (`_channel?.unsubscribe()`) before recreating or when screens unmount.

---

## ⚡ 4. Caching & Concurrent Fetching

1. **Parallel Queries (`Future.wait`)**:
   Execute non-dependent queries in parallel (e.g. notifications, user profile, active visits).

2. **Cache Eviction**:
   Limit in-memory cache lists (`profileCache`, `bookingCache`) to max 100 entries with automatic background re-validation (`forceRefresh: true`).

---

## 📱 5. UI Rendering & Pixel Overflow Safety

1. **Const Constructors**: Use `const` widgets wherever possible to enable element tree reuse.
2. **Overflow Guarding**: Wrap receipt detail rows and modal steppers in `Expanded`, `Flexible`, `FittedBox`, or `SingleChildScrollView` to eliminate red/yellow pixel overflow banners on all screen sizes.
