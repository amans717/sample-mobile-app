# CRM Call Sample (Flutter + Supabase)

A production-ready Android CRM mobile application built for executives to manage contacts, initiate phone calls, track call lifecycles, and automatically upload call recordings and metadata to Supabase.

Targeted and optimized for **Motorola G64 (Android 14 / API 34)**.

---

## 📱 Features

* **Instant Contact Import**: Reads contacts directly from the device and caches them locally in SQLite for rapid offline searching and loading. (Contacts are never uploaded to Supabase).
* **Realtime Contact Search**: Instant filtering by customer name or phone number.
* **Direct Native Calling**: Place calls with a single tap using native Android telephony.
* **Intelligent Call Lifecycle Tracking**: Detects when calls start (`OFFHOOK`) and end (`IDLE`) natively on Android 14 via `TelephonyCallback`.
* **Automatic Call Recording Uploads**: Detects audio files and uploads them automatically to Supabase Storage and Database.
* **Graceful Android 14 Fallback**: If call recording is restricted or unavailable on the device, displays `"Call completed. Recording unavailable on this device."` without crashing.
* **In-App Streaming Player**: Play, pause, seek, and download call recordings directly from Supabase Storage URLs.
* **Material 3 Design**: Enterprise CRM UI with primary green theme (`#16A34A`), slate background (`#F8FAFC`), and 18px rounded cards.

---

## 🛠️ Tech Stack & Architecture

* **Framework**: Flutter (Material 3)
* **Language**: Dart
* **Backend**: Supabase (Database & Storage)
* **Local Cache**: SQLite (`sqflite`)
* **State Management**: `Provider`
* **Architecture**: Clean Architecture
  ```
  lib/
  ├── main.dart
  ├── core/
  │   ├── constants/       # App colors & Supabase configuration
  │   ├── database/        # SQLite database helper (cached_contacts)
  │   ├── theme/           # Material 3 theme definitions
  │   └── utils/           # Date formatting & custom snackbars
  ├── models/              # ContactModel & CallRecordingModel
  ├── services/            # PermissionService, ContactService, CallService, RecordingService, SupabaseService, AudioPlayerService
  ├── repositories/        # ContactRepository & RecordingRepository
  ├── providers/           # ContactProvider, CallProvider, HistoryProvider
  ├── screens/             # SplashScreen, MainNavigationScreen, HomeScreen, HistoryScreen
  └── widgets/             # ContactCard, RecordingCard, PermissionDialog, AudioPlayerSheet, SearchBar
  ```

---

## 🚀 1. Flutter Setup

### Prerequisites
* Flutter SDK (3.19.0 or higher)
* Android SDK (API 34 / Android 14 platform tools)
* Java JDK 17

### Installation
1. Clone or navigate to the project directory:
   ```bash
   cd crm_call_sample
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```

---

## ⚡ 2. Supabase Setup

### Step 1: Configure Credentials
Open `lib/core/constants/supabase_constants.dart` and enter your Supabase Project credentials:

```dart
class SupabaseConstants {
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
  ...
}
```
*Alternatively, you can pass them via build environment arguments:*
```bash
flutter run --dart-define=SUPABASE_URL="https://YOUR_PROJECT_ID.supabase.co" --dart-define=SUPABASE_ANON_KEY="YOUR_ANON_KEY"
```

---

## 🗄️ 3. SQL Schema Migration

Go to your **Supabase Dashboard -> SQL Editor** and execute the following SQL script (also located in `supabase/schema.sql`):

```sql
-- Create call_recordings table
CREATE TABLE IF NOT EXISTS public.call_recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    file_url TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indices for rapid querying
CREATE INDEX IF NOT EXISTS idx_call_recordings_phone ON public.call_recordings(phone);
CREATE INDEX IF NOT EXISTS idx_call_recordings_created_at ON public.call_recordings(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.call_recordings ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Allow public read access on call_recordings"
ON public.call_recordings FOR SELECT TO public USING (true);

-- Allow public insert access
CREATE POLICY "Allow public insert access on call_recordings"
ON public.call_recordings FOR INSERT TO public WITH CHECK (true);

-- Allow public delete access
CREATE POLICY "Allow public delete access on call_recordings"
ON public.call_recordings FOR DELETE TO public USING (true);
```

---

## 📦 4. Storage Bucket Creation

1. In the Supabase Dashboard, go to **Storage -> New Bucket**.
2. Name the bucket: `call-recordings`.
3. Set the bucket to **Public**.
4. (Optional) Run the storage policy SQL from `supabase/schema.sql`:
   ```sql
   INSERT INTO storage.buckets (id, name, public)
   VALUES ('call-recordings', 'call-recordings', true)
   ON CONFLICT (id) DO UPDATE SET public = true;

   CREATE POLICY "Allow public read access to call-recordings bucket"
   ON storage.objects FOR SELECT TO public
   USING (bucket_id = 'call-recordings');

   CREATE POLICY "Allow public upload to call-recordings bucket"
   ON storage.objects FOR INSERT TO public
   WITH CHECK (bucket_id = 'call-recordings');
   ```

### Storage File Hierarchy
Uploaded files follow the exact hierarchy:
```
year/month/day/phone_timestamp.m4a
```
Example: `2026/09/16/9876543210_1726500000.m4a`

---

## 🔒 5. AndroidManifest Permissions

The app contains all mandatory permissions configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Contacts & Telephony -->
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- Audio & Android 14 Foreground Service -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />

<!-- Storage & Notifications -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 📱 6. Motorola G64 (Android 14) Testing Instructions

1. Connect your **Motorola G64** via USB and enable **USB Debugging** in *Developer Options*.
2. Verify device connection:
   ```bash
   flutter devices
   ```
3. Run the app:
   ```bash
   flutter run -d <your-moto-g64-device-id>
   ```
4. **On First Launch**:
   - The splash screen will request permissions (`Contacts`, `Phone`, `Microphone`, `Audio`, `Notifications`).
   - Tap **Allow** for all permissions.
   - If denied, the app will display a friendly dialog allowing you to tap **Open Settings**.
5. **Testing Contact Search**:
   - The app reads contacts and saves them into the local SQLite database.
   - Type in the search bar to test realtime name and phone number filtering.
6. **Testing Calling Flow**:
   - Tap the green phone button next to any contact.
   - The app launches the native phone dialer and monitors the call lifecycle.
   - When the call concludes, return to the app.
   - The app captures the recording, uploads it to Supabase Storage, and adds a record to the database.
   - If the device dialer did not produce an accessible recording, the app notifies:
     `"Call completed. Recording unavailable on this device."` without crashing.
7. **Testing Audio History & Playback**:
   - Switch to the **History** tab.
   - Tap **Play** on any card to stream the recording directly from Supabase Storage.
   - Test **Download** and **Delete** actions.

---

## ⚖️ 7. Known Android 14 Limitation About Call Recording

> [!IMPORTANT]
> **Android 14 Privacy & Sandbox Architecture:**
> 1. **System Call Recording API Removal**: Starting from Android 9/10, Google permanently restricted access to the `VOICE_CALL` and `VOICE_COMMUNICATION` audio sources for third-party applications without system/OEM root permissions.
> 2. **Accessibility API Bans**: In Android 14 (API 34), Google Play Policies and OS sandboxing strictly block using `AccessibilityServices` as a workaround for recording cellular calls.
> 3. **Motorola / Google Dialer Behavior**:
>    - The native Google Dialer on Motorola devices in supported carrier regions records calls when the user explicitly taps "Record" during a call.
>    - Depending on regional firmware, Google Dialer stores recordings either in the internal app private database or in `/storage/emulated/0/Recordings/Call`.
> 4. **How CRM Call Sample Solves This Gracefully**:
>    - **Dual-Engine Architecture**:
>      1. *Engine 1 (In-App Recorder)*: Runs an in-app microphone recorder with `FOREGROUND_SERVICE_MICROPHONE` during the call.
>      2. *Engine 2 (Device Scanner)*: Scans the standard Android call recordings directories (`/Recordings/Call`, `/Music/Recordings/`, etc.) for newly created audio files corresponding to the phone number and call timestamp.
>    - If an audio file is captured, it is automatically formatted and uploaded to Supabase.
>    - If restricted by the device OEM or region, the app notifies the executive with `"Call completed. Recording unavailable on this device."` and never crashes.
