# Sampriti (সম্প্রীতি ইনভেস্টমেন্ট ফোরাম)
## Google Play Store Production Release Guide & Architecture Audit

---

## 1. Executive Project Summary

* **App Name:** Sampriti (সম্প্রীতি / সম্প্রীতি ইনভেস্টমেন্ট ফোরাম)
* **Application ID / Package Name:** `com.thinkcodify.sampriti`
* **Flutter Version:** 3.38.7
* **Dart SDK:** 3.10.7
* **Android Gradle Plugin (AGP):** 8.11.1 (Kotlin DSL `build.gradle.kts`)
* **Gradle Wrapper:** 8.14
* **Database:** Google Cloud Firestore (Firebase Project: `sampriti-90818`)
* **Authentication Method:** Custom Client-side SHA-256 / PBKDF2 Hashing against Firestore

---

## 2. Architecture & Tech Stack Analysis

### A. Authentication System (Custom / Non-Firebase Auth)
The app **does not** use standard Firebase Authentication (`FirebaseAuth`). Instead, authentication is custom-built on top of Cloud Firestore and local device storage:

* **Admin Authentication:**
  * Admin enters password.
  * Trimmed password is hashed via PBKDF2/SHA-256 (`HashHelper.fastHash`).
  * Compared against `adminPwHash` in Firestore document `settings/org_config`.
  * On success, role `admin` is persisted in `SharedPreferences`.
* **Shareholder Authentication:**
  * Member enters Share Number (e.g., `M-001`) and numeric PIN (4–6 digits).
  * Formatted as `${cleanNo}|${cleanPin}` and hashed via `HashHelper.fastHash`.
  * Compared against the `pin` field in Firestore document `members/{cleanNo}`.
  * On success, role `shareholder`, member number, and name are stored in `SharedPreferences`.
* **Key Finding:**
  `firebase_auth` is imported in `pubspec.yaml` and registered in `service_locator.dart`, but is **never used**. Because Firebase Auth is not used, Firestore requests are executed unauthenticated (`request.auth == null`).

### B. Database & Data Storage
* **Firestore Collections:**
  * `members`: Member bio data, shares count, nominee details, mobile, status, and Base64 photo.
  * `transactions`: Vouchers, deposits, loan records, bank/cash balances, and dividend payouts.
  * `settings/org_config`: Admin credentials and organizational fund split ratios (`f`, `l`, `m`, `cash0`).
* **Photo Storage:**
  * Photos are not stored in Firebase Storage. They are compressed via `image_picker` (280×360 at 82% quality) and stored directly as Base64 strings inside the Firestore member document.

### C. PDF & Document Generation
* Uses `bangla_pdf`, `pdf`, and `printing` to generate Share Certificates, Shareholder Forms, Member Statements, and Vouchers in Bengali.
* **Note:** `PdfDocumentService` loads Noto Sans Bengali dynamically via HTTP Google Fonts (`PdfGoogleFonts.notoSansBengaliRegular()`). Bundling local `.ttf` font files in `assets/fonts/` is recommended for 100% offline reliability.

---

## 3. Critical Security Findings & Pre-Release Fixes

### 🚨 Critical Vulnerability 1: Leaked Google Cloud Service Account Private Key
* **Location:** `lib/core/config/service_account_key.dart`
* **Finding:** Contains a full plaintext private key (`-----BEGIN PRIVATE KEY-----`) for project `work-pulse-app-4a8a7` (used by `access_token_generator.dart` for commented-out FCM code).
* **Action Required:**
  1. Revoke and delete this service account key immediately in the Google Cloud Console for project `work-pulse-app-4a8a7`.
  2. Delete `lib/core/config/service_account_key.dart` and `lib/core/services/access_token_generator.dart`.

### 🚨 Critical Vulnerability 2: Open Firestore Security Rules
* **Location:** `firestore.rules`
* **Finding:** Currently allows full open read and write access:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /{document=**} {
        allow read, write: if true;
      }
    }
  }
  ```
* **Risk:** Anyone inspecting the app can modify or wipe all member records and transactions.
* **Action Required:** Restrict write permissions, enforce data validation rules, protect `settings/org_config`, and enable Firebase App Check to prevent unauthorized API calls.

### 🚨 Play Store Rejection Risk 3: Unused Location & Wi-Fi Permissions
* **Location:** `pubspec.yaml`
* **Finding:** The following packages are declared in `pubspec.yaml` but never used in any app feature:
  * `location: ^8.0.1`
  * `geolocator: ^14.0.2`
  * `geocoding: ^4.0.0`
  * `network_info_plus: ^7.0.0`
* **Risk:** Android Gradle manifest merger automatically injects `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, and `ACCESS_WIFI_STATE`. Google Play Console rejects apps that request location permissions without an active, user-facing location feature.
* **Action Required:** Remove these packages from `pubspec.yaml`.

### ⚠️ Issue 4: Missing `INTERNET` Permission in Main Android Manifest
* **Location:** `android/app/src/main/AndroidManifest.xml`
* **Finding:** `android.permission.INTERNET` is only in `src/debug/AndroidManifest.xml`.
* **Action Required:** Add `<uses-permission android:name="android.permission.INTERNET"/>` directly to `src/main/AndroidManifest.xml`.

### ⚠️ Issue 5: Release Build Configured with Debug Signing Keys
* **Location:** `android/app/build.gradle.kts`
* **Finding:** `signingConfig = signingConfigs.getByName("debug")` is set for release.
* **Action Required:** Configure release signing via `key.properties`.

### ⚠️ Issue 6: Keystores Not Ignored in Git
* **Location:** `.gitignore`
* **Action Required:** Add `*.jks`, `*.keystore`, and `key.properties` to `.gitignore`.

---

## 4. App Signing & SHA Fingerprint Requirements

### Do you need SHA-1 / SHA-256?
* **For Authentication:** **No.** Custom PIN/password hashing does not require SHA-1 registration in Firebase Console.
* **For Google Play App Signing:** **Mandatory.** Google Play requires Google Play App Signing:
  1. **Upload Key (Local Keystore):** Created on your machine. Signs the AAB before uploading to Google Play Console.
  2. **App Signing Key (Google Play):** Managed by Google Play. Google verifies your upload key, strips it, and re-signs the APKs delivered to users.
* **For Firebase App Check (Recommended):** If you enable Firebase App Check (Play Integrity Provider) to safeguard Firestore, you will copy the **SHA-256 from Google Play Console (App Integrity)** into the Firebase Console.

---

## 5. Step-by-Step Setup Guide

### Step 1: Generate Release Keystore
Run in PowerShell from the project root:

```powershell
keytool -genkeypair -v -keystore android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*Provide a secure password and enter your developer details when prompted.*

### Step 2: Extract Keystore Fingerprints
```powershell
keytool -list -v -keystore android\app\upload-keystore.jks -alias upload
```
*Store the SHA-1 and SHA-256 values in your private release notes.*

### Step 3: Create `android/key.properties`
Create `android/key.properties` with:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 4: Protect Credentials in `.gitignore`
Add the following to `.gitignore`:

```gitignore
# Keystore & Signing Credentials
*.jks
*.keystore
**/android/key.properties
```

### Step 5: Update `android/app/build.gradle.kts`
Update the file to load `key.properties` in Kotlin DSL and enable R8 code shrinking:

```kotlin
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.thinkcodify.sampriti"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.thinkcodify.sampriti"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### Step 6: Create ProGuard Rules (`android/app/proguard-rules.pro`)
Create `android/app/proguard-rules.pro`:

```proguard
# Flutter Engine Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (Deferred Components in Flutter Engine)
-dontwarn com.google.android.play.core.**

# Google & Firebase
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }

# Desugaring
-dontwarn java.lang.invoke.**
-dontwarn java.time.**
```

### Step 7: Update `android/app/src/main/AndroidManifest.xml`
Ensure permissions and camera hardware declarations are present:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <!-- Optional Camera for Member Profile Photos -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <application
        android:label="Sampriti"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
```

### Step 8: Clean Up Dependencies in `pubspec.yaml`
1. Remove:
   * `location`
   * `geolocator`
   * `geocoding`
   * `network_info_plus`
   * `dio`
   * `googleapis_auth`
   * `firebase_auth`
   * `firebase_storage`
   * `firebase_messaging`
   * `flutter_local_notifications`
2. Remove `DevicePreview` wrapper from `lib/main.dart`:
   ```dart
   return runApp(const MyApp());
   ```

---

## 6. Google Play Console Listing & Policy Requirements

| Item | Value / Requirement | Notes |
| :--- | :--- | :--- |
| **Package Name** | `com.thinkcodify.sampriti` | Must match `applicationId`. |
| **Target SDK** | Android 14 / 15 (API 34/35) | Enforced by Play Console. |
| **Privacy Policy URL** | `https://sampriti.org/privacy` | Must detail collection of Name, Phone, Photos, Financial Transactions. |
| **Category** | Finance / Business | Selected in App settings. |
| **Target Age** | 18 and over | Policy > Target Audience. |
| **Ads Declaration** | "No, my app does not contain ads" | Policy > Ads. |
| **Financial Features** | Cooperative / Investment Tracking | Policy > Financial features declaration. |
| **Data Safety** | Name, Phone, Photo, Member ID, Financial Info | Declare data encrypted in transit (HTTPS/TLS) and not sold to third parties. |
| **Closed Testing** | **20 Testers for 14 Continuous Days** | Mandatory for personal Play Console developer accounts created after Nov 13, 2023. |

---

## 7. Build Commands & Verification

### Clean & Fetch Dependencies
```powershell
flutter clean
flutter pub get
```

### Run Tests & Analysis
```powershell
flutter analyze
flutter test
```

### Build Signed Release App Bundle (AAB) with Obfuscation
```powershell
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Verify Output Bundle Signature
```powershell
keytool -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```
*Verify that the Owner and Issuer match your `upload` keystore details (not Android Debug).*

---
*Created on 2026-11-11 for Sampriti Investment Forum by ThinkCodify.*
