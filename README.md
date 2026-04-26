# Talkest.

![Push Notifications](https://img.shields.io/badge/Update-Push%20Notifications%20Now%20Live!-orange?style=for-the-badge&logo=firebase)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-brightgreen?style=flat)

A simple real-time messaging app built with Flutter, Firebase (Auth, Cloud Firestore) and Vercel (Serverless Functions) - designed for a single purpose: **let people reach you directly from your personal website.**

No need to share social media links. No need for third-party contact forms.  
Just embed Talkest on your website, and anyone with a Google account can start a conversation with you instantly.

> **Why does this exist?**  
> I built Talkest because I wanted a simple _"get in touch"_ solution for [my portfolio website](https://khip01.github.io/me/). Instead of redirecting visitors to social media, they can just chat with me right there, powered by a Flutter Web widget embedded directly into the page.

## ✨ Features

- **Real-time messaging** — Powered by Cloud Firestore with live message streaming
- **Google Sign-In** — One-tap authentication, no extra account needed
- **Light & Dark theme** — With system theme detection and manual toggle
- **QR Code profile** — Each user gets a personal QR code for quick contact sharing
- **QR Scanner** — Scan someone's QR code to start a chat instantly
- **Start chat by email** — Find and message any registered user by their email address
- **Editable display name** — Customize how your name appears to others
- **Embeddable chat widget** — Deploy the Flutter Web build and embed it on any website via iframe
- **Native mobile app** — Install the Android app to monitor and reply to incoming messages on the go
- **Push Notifications** — High-priority alerts with heads-up display, custom sounds, and auto-dismissal when chat is read.
- **Deep Linking** — Clicking a notification takes you directly to the relevant chat room.

## 📦 Available Platforms

| Platform          | Status       | Link                                                          |
| ----------------- | ------------ | ------------------------------------------------------------- |
| **Android**       | ✅ Available | [Github release](https://github.com/Khip01/talkest/releases)  |
| **Web**           | ✅ Available | [khip01.github.io/talkest](https://khip01.github.io/talkest/) |
| **Embedded mode** | ✅ Available | Used on [my portfolio](https://khip01.github.io/me/)          |
| **iOS**           | ❌ Not yet   | _No Mac device available for development_                     |

## 📸 Screenshots

<!--
  ┌─────────────────────────────────────────────────────────────────┐
  │  HOW TO ADD SCREENSHOTS:                                       │
  │                                                                 │
  │  1. Take your screenshots                                      │
  │  2. Add them to a folder (e.g., assets/screenshots/)            │
  │     or upload to GitHub issue/imgur and use the URL              │
  │  3. Replace the placeholder YOUR_IMAGE_URL_HERE below           │
  │                                                                 │
  │  Recommended image width for mobile: ~280px                     │
  │  Recommended image width for web/embed: ~600px                  │
  └─────────────────────────────────────────────────────────────────┘
-->

### Mobile App

<table>
  <tr>
    <td width="33%" align="center"><b>Login</b></td>
    <td width="33%" align="center"><b>Chat List</b></td>
    <td width="33%" align="center"><b>Messaging</b></td>
  </tr>
  <tr>
    <td align="center"><img src="https://i.ibb.co.com/9m2M5kmQ/login-screen.jpg" alt="Login Screen"></td>
    <td align="center"><img src="https://i.ibb.co.com/6crStjh2/chat-list.jpg" alt="Chat List"></td>
    <td align="center"><img src="https://i.ibb.co.com/0RHtj9h9/chat-messages.jpg" alt="Chat Detail"></td>
  </tr>
</table>

### Embedded Mode (on website)

|                             Embed mode — Landing page on portfolio website                              |
| :-----------------------------------------------------------------------------------------------------: |
| <img src="https://i.ibb.co.com/DHTnVznT/embed-landing-screen.png" alt="Embed Landing Page" width="600"> |

|                           Embed mode — Chat view on portfolio website                           |
| :---------------------------------------------------------------------------------------------: |
| <img src="https://i.ibb.co.com/hRBSzRnH/embed-chat-view.png" alt="Embed Chat View" width="600"> |

## 🛠 Tech Stack

| Category            | Technology                                                       |
| ------------------- | ---------------------------------------------------------------- |
| Framework           | [Flutter](https://flutter.dev/) (Dart)                           |
| Backend (Primary)   | [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore) |
| Backend (Functions) | [Vercel](https://vercel.com/) (Serverless Functions Node.js)     |
| Push Notifications  | Firebase Cloud Messaging (FCM v1)                                |
| Authentication      | Google Sign-In                                                   |
| State Management    | BLoC + Provider                                                  |
| Routing             | GoRouter                                                         |
| Deployment          | GitHub Pages (Web), APK (Android)                                |

---

## 🔧 Development Setup

### Prerequisites

- Flutter SDK
- Firebase project with Authentication and Cloud Firestore enabled
- Google OAuth 2.0 Client ID (for Flutter Web only)

---

### Firestore Structure

Collections and documents are **created automatically** when the app runs for the first time — no manual setup needed. Below is the database structure for reference:

```
├── app_users (collection)
│   └── {uid} (document)
│       ├── name: string
│       ├── displayName: string
│       ├── email: string
│       ├── photoUrl: string
│       ├── provider: string
│       ├── fcmToken: string (optional)
│       ├── createdAt: timestamp
│       ├── updatedAt: timestamp
│       └── lastLoginAt: timestamp
│
└── chats (collection)
    └── {chatId} (document)
        ├── type: string ("direct")
        ├── participants: array [uid1, uid2]
        ├── createdAt: timestamp
        ├── updatedAt: timestamp
        ├── unreadCount: map { uid1: number, uid2: number }
        ├── lastMessage: map
        │   ├── id: string
        │   ├── senderId: string
        │   ├── text: string
        │   ├── type: string
        │   ├── createdAt: timestamp
        │   └── isDeleted: boolean
        │
        └── 📁 messages (subcollection)
            └── {messageId} (document)
                ├── id: string
                ├── chatId: string
                ├── senderId: string
                ├── type: string
                ├── text: string
                ├── createdAt: timestamp
                ├── editedAt: timestamp (optional)
                ├── isDeleted: boolean
                ├── replyToId: string (optional)
                ├── replyToSenderId: string (optional)
                ├── replyToSenderName: string (optional)
                └── replyToText: string (optional)
```

---

### Firestore Security Rules

Security rules are defined in [`firestore.rules`](firestore.rules).

> [!IMPORTANT]
> The included rules are stricter than the default test-mode rules. They enforce that:
>
> - Users can only **write** to their own profile
> - Only chat **participants** can read/write chats and messages
> - Messages can only be **created** (no editing or deleting from client)
>
> Review and adjust the rules in [`firestore.rules`](firestore.rules) to fit your needs before deploying.

---

### Firestore Indexes

This project requires a composite index for querying chats. The index configuration is defined in [`firestore.indexes.json`](firestore.indexes.json).

| Collection | Fields                                            | Query Scope |
| ---------- | ------------------------------------------------- | ----------- |
| `chats`    | `participants` (Array) + `updatedAt` (Descending) | Collection  |

> [!TIP]
> If you skip deploying indexes, Firestore will show an error with a direct link to create the required index when the app first runs a query that needs it.

---

### Deploying Firestore Rules & Indexes

Deploy both rules and indexes at once:

```bash
firebase deploy --only firestore --project YOUR_PROJECT_ID
```

Or deploy them individually if needed:

```bash
firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
firebase deploy --only firestore:indexes --project YOUR_PROJECT_ID
```

> [!TIP]
> If you skip this step, Firestore will show an error with a direct link to create the required index when the app first runs a query that needs it.

---

### Getting OAuth 2.0 Client ID

1. **Via Firebase Console** (Recommended):
   - Open [Firebase Console](https://console.firebase.google.com)
   - Select your project → **Project Settings**
   - Add a Web app (if not already added)
   - The Client ID will be auto-generated in Google Cloud Console

2. **Manual Setup**:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Navigate to **APIs & Services** → **Credentials**
   - Create **OAuth client ID** → Select **Web application**
   - Configure:
     - **Authorized JavaScript origins**:
       - `http://localhost`
       - `http://localhost:5000`
       - `https://your-domain.firebaseapp.com` (production)
     - **Authorized redirect URIs**:
       - `https://your-domain.firebaseapp.com/__/auth/handler`
   - Copy the generated **Client ID**

---

### Android & Google Sign-In (Local Debug)

To run the Android app locally (`.debug` flavor) and ensure Google Sign-In works, you must register your local **SHA-1** fingerprint with your Firebase project.

#### 1. Generate SHA-1
Run the following command in your terminal:
```bash
cd android && ./gradlew signingReport
```
> [!NOTE] 
> Look for `Variant: debug` → `Config: debug` and copy the `SHA1` string.

#### 2. Firebase Configuration
| Step                 | Action |
|:---------------------| :--- |
| **Register App**     | Add a new Android app in Firebase Console with package: `com.khip.talkest.debug`. |
| **Add Fingerprints** | Paste the **SHA-1** & **SHA-256** into the Firebase Console for this debug app. |
| **Sync File**        | Download the updated `google-services.json` and replace the one in `android/app/`. |

#### 3. Clean & Run
Reset the build cache to apply new configurations:
```bash
flutter clean && flutter pub get
cd android && ./gradlew clean && cd ..
flutter run -d <device-id> --dart-define=VERCEL_API_URL=https://your-talkest-api.vercel.app
```

---

### Push Notification Setup (Vercel)

Talkest utilizes a **Node.js Serverless Function** deployed on Vercel as a secure proxy for FCM v1 delivery.

> **Security Note:**  \
> To prevent credential leaks, Talkest uses a **Zero-Secret Architecture**. The client dynamically fetches a **Firebase ID Token** from the authenticated user and passes it as a `Bearer` token. The Vercel API verifies this token against Firebase Admin before executing the push request.

#### 🛠️ Deployment Steps

1. **Backend Repository:** Clone the [talkest-api repository](https://github.com/Khip01/talkest-api).
2. **Firebase Private Key:** Go to `Project Settings` → `Service Accounts` → `Generate new private key` and download the JSON file.
3. **Vercel Configuration:**

   | Variable Name | Value |
   | :--- | :--- |
   | `FIREBASE_SERVICE_ACCOUNT` | *Paste the entire content of the downloaded JSON key* |

#### 🔗 Linking to Flutter
Pass your Vercel deployment URL during the build or run process:

```bash
flutter build apk --release \
  --dart-define=VERCEL_API_URL=https://your-talkest-api.vercel.app
```

---

### Running the App

**Web (Development):**

```bash
flutter run -d chrome \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com \
  --dart-define=VERCEL_API_URL=https://your-talkest-api.vercel.app
```

**Mobile (Android/iOS):**

```bash
flutter run -d <device-id> \
  --dart-define=VERCEL_API_URL=https://your-talkest-api.vercel.app
```

### Building for Production:

**Web (Release)**

```bash
flutter build web --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_ID.apps.googleusercontent.com \
  --dart-define=VERCEL_API_URL=https://your-talkest-api.vercel.app
```

> [!IMPORTANT]
> Web builds require the Google Web Client ID for authentication.

**Mobile (Release)**

```bash
flutter build apk --release \
  --dart-define=VERCEL_API_URL=https://your-talkest-api.vercel.app
```

> [!IMPORTANT]
> Mobile builds require the `VERCEL_API_URL` to successfully trigger push notifications.


---

### Embed Mode

Talkest supports an embedded chat widget mode, designed to be loaded inside an `<iframe>` on any website. This allows visitors to chat with a specific user directly from your page.

**URL format:**

```
https://your-talkest-deployment.com/?embed=1&targetUid=FIREBASE_USER_UID
```

**Example iframe usage:**

```html
<iframe
  src="https://khip01.github.io/talkest/?embed=1&targetUid=YOUR_FIREBASE_UID"
  width="400"
  height="600"
  style="border: none; border-radius: 12px;"
  allow="clipboard-read; clipboard-write"
></iframe>
```

**Parameters:**
| Parameter | Required | Description |
|-----------|----------|-------------|
| `embed` | Yes | Set to `1` to activate embedded mode |
| `targetUid` | Yes | The Firebase UID of the user to chat with |

> [!TIP]
> You can find your Firebase UID in the [Firebase Console](https://console.firebase.google.com) → **Authentication** → **Users** tab.

In embed mode, the app will:

- Show a landing page with a sign-in prompt for unauthenticated visitors
- Automatically open a direct chat with the target user after sign-in
- Hide navigation elements like the FAB and profile access for a clean widget experience

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)

---

## ⚠️ Troubleshooting

**Google Sign-In Error: `[16] Account reauth failed`**

This error occurs on Android when the SHA-1 fingerprint of the machine compiling the app does not match the fingerprint registered in Firebase.

When you clone this repository, your machine generates its own unique `debug.keystore`. The Google Sign-In package blocks authentication because your local fingerprint is not whitelisted. To fix this, follow the steps in the **Android Configuration & Google Sign-In** section above to register your personal local SHA-1 fingerprint to your Firebase project and update the `google-services.json` file.

---

<p align="center">
  Made with 🤍 by <a href="https://github.com/khip01">Khip01</a>
</p>
