# talkest

Talkest is a messaging platform featuring an embedded Flutter Web chat widget, Firebase-based authentication with Google Sign-In, and real-time messaging.

> [!NOTE] 
> Push notifications are currently not implemented.  
> A complete push notification flow requires Firebase Cloud Functions to trigger Firebase Cloud Messaging (FCM), which depends on the Blaze (pay-as-you-go) plan.


## Development Setup

### Prerequisites
- Flutter SDK
- Firebase project with Authentication enabled
- Google OAuth 2.0 Client ID (Flutter Web Only)

### Getting OAuth 2.0 Client ID

1. **Via Firebase Console** (Recommended):
   - Open [Firebase Console](https://console.firebase.google.com)
   - Select your project → Project Settings
   - Add Web app (if not already added)
   - Client ID will be auto-generated in Google Cloud Console

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
flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

**Mobile (Android/iOS):**
```bash
flutter run
```

**Building for Production:**
```bash
flutter build web --wasm --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
