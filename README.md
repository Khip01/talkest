# Talkest.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-brightgreen?style=flat)

A simple real-time messaging app built with Flutter & Firebase - designed for a single purpose: **let people reach you directly from your personal website.**

No need to share social media links. No need for third-party contact forms.  
Just embed Talkest on your website, and anyone with a Google account can start a conversation with you instantly.

> **Why does this exist?**  
> I built Talkest because I wanted a simple _"get in touch"_ solution for [my portfolio website](https://khip01.github.io/me/). Instead of redirecting visitors to social media, they can just chat with me right there,  powered by a Flutter Web widget embedded directly into the page.

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

## 📦 Available Platforms

| Platform | Status | Link |
|----------|--------|------|
| **Android** | ✅ Available | [Github release](https://github.com/Khip01/talkest/releases) |
| **Web** | ✅ Available | [khip01.github.io/talkest](https://khip01.github.io/talkest/) |
| **Embedded mode** | ✅ Available | Used on [my portfolio](https://khip01.github.io/me/) |
| **iOS** | ❌ Not yet | _No Mac device available for development_ |

> [!NOTE]
> Push notifications are currently not implemented.  
> A complete push notification flow requires Firebase Cloud Functions to trigger Firebase Cloud Messaging (FCM), which depends on the Blaze (pay-as-you-go) plan.

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

<p align="center">
  <img src="YOUR_IMAGE_URL_HERE" alt="Login Screen" width="280">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="YOUR_IMAGE_URL_HERE" alt="Chat List" width="280">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="YOUR_IMAGE_URL_HERE" alt="Chat Detail" width="280">
</p>

<p align="center">
  <em>Login</em>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Chat List</em>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Messaging</em>
</p>

### Embedded Mode (on website)

<p align="center">
  <img src="YOUR_IMAGE_URL_HERE" alt="Embed Landing Page" width="600">
</p>
<p align="center"><em>Embed mode — Landing page on portfolio website</em></p>

<br>

<p align="center">
  <img src="YOUR_IMAGE_URL_HERE" alt="Embed Chat View" width="600">
</p>
<p align="center"><em>Embed mode — Chat view on portfolio website</em></p>

## 🛠 Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | [Flutter](https://flutter.dev/) (Dart) |
| Backend | [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore) |
| Authentication | Google Sign-In |
| State Management | BLoC + Provider |
| Routing | GoRouter |
| Deployment | GitHub Pages (Web), APK (Android) |

---

## 🔧 Development Setup

### Prerequisites

- Flutter SDK
- Firebase project with Authentication and Cloud Firestore enabled
- Google OAuth 2.0 Client ID (for Flutter Web only)

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
        │   └── createdAt: timestamp
        │
        └── 📁 messages (subcollection)
            └── {messageId} (document)
                ├── id: string
                ├── chatId: string
                ├── senderId: string
                ├── type: string
                ├── text: string
                └── createdAt: timestamp
```

### Firestore Security Rules

Security rules are defined in [`firestore.rules`](firestore.rules).

> [!IMPORTANT]
> The included rules are stricter than the default test-mode rules. They enforce that:
> - Users can only **write** to their own profile
> - Only chat **participants** can read/write chats and messages
> - Messages can only be **created** (no editing or deleting from client)
>
> Review and adjust the rules in [`firestore.rules`](firestore.rules) to fit your needs before deploying.

### Firestore Indexes

This project requires a composite index for querying chats. The index configuration is defined in [`firestore.indexes.json`](firestore.indexes.json).

| Collection | Fields | Query Scope |
|------------|--------|-------------|
| `chats` | `participants` (Array) + `updatedAt` (Descending) | Collection |

> [!TIP]
> If you skip deploying indexes, Firestore will show an error with a direct link to create the required index when the app first runs a query that needs it.

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

### Running the App

**Web (Development):**
```bash
flutter run -d <web-device> --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

**Mobile (Android/iOS):**
```bash
flutter run -d <device-id>
```

### Building for Production:

**Web (Release)**
```bash
flutter build web --elease --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```
> [!IMPORTANT]
> Web builds require the Google Web Client ID for authentication.

**Mobile (Release)**
```bash
flutter build --release
```
> Mobile builds do not require additional parameters and can be built normally in release mode.


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

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)

---

<p align="center">
  Made with 🤍 by <a href="https://github.com/khip01">Khip01</a>
</p>
