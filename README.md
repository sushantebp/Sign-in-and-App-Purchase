# 🍎 Sign In With Apple (SIWA): A Comprehensive Technical Guide

> This document details the essential setup, core concepts, and server-side requirements for successfully integrating **Sign In with Apple (SIWA)** into a Flutter mobile application, covering both native (iOS) and web-based (Android/Web) authentication flows.

---

## 📋 Table of Contents

1.  [Core Concepts: Native vs. Web Flow](#1-core-concepts-native-vs-web-flow)
    - [1.1. 🍏 iOS (Native Flow)](#11-ios-native-flow)
    - [1.2. 🤖 Android/Web (Web Flow)](#12-androidweb-web-flow)
2.  [Apple Developer Portal Setup](#2-apple-developer-portal-setup)
    - [2.1. 🔑 Prerequisite Identifiers](#21--prerequisite-identifiers)
    - [2.2. 🛠️ Configuration Steps](#22--configuration-steps)
3.  [Server-Side Credential Handling](#3-server-side-credential-handling)
    - [3.1. A. Token Exchange (Android/Web Flow)](#31-a-token-exchange-androidweb-flow)
    - [3.2. B. Identity Token Verification (iOS Native Flow)](#32-b-identity-token-verification-ios-native-flow)
    - [3.3. C. Session Maintenance & Revocation](#33-c-session-maintenance--revocation)
4.  [Platform-Specific Implementation Summary](#4-platform-specific-implementation-summary)
    - [4.1. 🍏 iOS Setup (Xcode)](#41-ios-setup-xcode)
    - [4.2. 🤖 Android/Web Setup (Web Authentication)](#42-androidweb-setup-web-authentication)
    - [4.3. Flutter Implementation Snippet](#43-flutter-implementation-snippet)

---

## 1. Core Concepts: Native vs. Web Flow

Integrating SIWA requires handling two fundamentally different authentication paths, determined by the client platform. Your backend server **must** be configured to support both for full platform coverage.

### 1.1. 🍏 iOS (Native Flow)

| Feature           | Description                                                                                                      |
| :---------------- | :--------------------------------------------------------------------------------------------------------------- |
| **Utilizes**      | The **Native Flow** (via `AuthenticationServices` framework).                                                    |
| **Mechanism**     | Communicates directly with the secure **Operating System (OS)** (Face ID/Touch ID) for authentication.           |
| **Primary ID**    | **App ID** (Bundle Identifier) configured with the SIWA capability.                                              |
| **Server Action** | **Identity Token Verification** (Verifying the signature against Apple's public key). This is the quickest path. |

### 1.2. 🤖 Android/Web (Web Flow)

| Feature           | Description                                                                                         |
| :---------------- | :-------------------------------------------------------------------------------------------------- |
| **Utilizes**      | The **Web Flow** (OAuth 2.0 / OpenID Connect).                                                      |
| **Mechanism**     | Opens a secure browser web view that redirects to the configured **Redirect URI** upon success.     |
| **Primary ID**    | **Service ID** (acts as the `client_id`).                                                           |
| **Server Action** | **Mandatory Full Token Exchange** using the Authorization Code and the generated **Client Secret**. |

---

## 2. Apple Developer Portal Setup

A **paid Apple Developer Account** is a mandatory prerequisite. This section outlines the essential identifiers required for both client and server interaction.

### 2.1. 🔑 Prerequisite Identifiers

| Identifier Type            | Purpose                                                                                             | Primary Use Case           | Critical Notes                                                         |
| :------------------------- | :-------------------------------------------------------------------------------------------------- | :------------------------- | :--------------------------------------------------------------------- |
| **App ID**                 | Primary identifier for the iOS app (Bundle ID).                                                     | **iOS Native Flow**        | Must match the bundle identifier in Xcode.                             |
| **Service ID**             | Identifier for web authentication and server-side requests.                                         | **Android & Web Flow**     | Used as the `client_id` for Web Flow.                                  |
| **Private Key (.p8 file)** | Used to digitally sign the **Client Secret** (a JWT) for server-to-server communication with Apple. | **Server-Side Validation** | **One-time download.** Do not lose this file or its associated Key ID. |

### 2.2. 🛠️ Configuration Steps

#### Step 1: Register and Configure App IDs (for iOS)

1.  Go to **Identifiers** and register a new **App ID**.
2.  Enable the **'Sign in with Apple'** capability under the App ID's configuration.
3.  This App ID is referenced in the iOS client's entitlements.

#### Step 2: Register Service IDs (for Android & Web)

1.  Register a new **Service ID** under **Identifiers**.
2.  Crucially, **link the Service ID to the primary App ID** (created in Step 1).
3.  Configure **Web Authentication**:
    - Provide the required **Redirect URI** (must be an HTTPS URL).
    - The Service ID will be the **`clientID`** used in the Android/Web flow.

#### Step 3: Create and Download the Private Key

1.  Navigate to the **Keys** section of the Developer Portal.
2.  Create a new key and specifically enable the **'Sign in with Apple'** option.
3.  **Immediately download the Private Key (.p8)** file and note the **Key ID**.
    > **⚠️ Warning:** This key is a shared secret; it is **downloaded only once** and is critical for your backend to prove its identity to Apple.

---

## 3. Server-Side Credential Handling

The server is the trusted component responsible for verifying the authenticity of the credentials provided by the Flutter client.

### 3.1. A. Token Exchange (Android/Web Flow)

This is a mandatory step for Web Flow authentication to obtain the final tokens.

| Step                   | Action                                                                                                                           | Credentials Used                                                 | Target Endpoint                        |
| :--------------------- | :------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------- | :------------------------------------- |
| **1. Receive**         | Backend receives the `authorizationCode` from the client.                                                                        | `authorizationCode`                                              | N/A                                    |
| **2. Generate Secret** | Backend uses the private **.p8 key** and its **Key ID** to dynamically generate a time-limited **Client Secret** (a signed JWT). | `.p8` Key, Key ID                                                | N/A                                    |
| **3. Request**         | Backend sends a POST request for token exchange.                                                                                 | `authorizationCode`, `Service ID` (`client_id`), `Client Secret` | `https://appleid.apple.com/auth/token` |
| **4. Receive Tokens**  | Apple validates the secret and returns the final **Access Token** and **Refresh Token** to the server.                           | N/A                                                              | Final Tokens                           |

### 3.2. B. Identity Token Verification (iOS Native Flow)

This is the fastest verification path, leveraging the secure nature of the Native Flow.

1.  **Receive:** Backend receives the **`identityToken`** from the client.
2.  **Verify Signature:** Backend retrieves Apple's public key (from the `/auth/keys` endpoint) and verifies the **digital signature** on the **`identityToken`** (a JWT).
3.  **Validate Claims:** Ensure the token's `aud` (audience) claim matches your **App ID** and the `iss` (issuer) is correct.

### 3.3. C. Session Maintenance & Revocation

- **Session Refresh:** Use the **`refreshToken`** (obtained during the exchange) to periodically verify the user's account status with Apple without forcing a re-login.
- **Revocation:** Implement logic to receive and process real-time **Server-to-Server Notifications** from Apple, which signal immediate user authorization revocation.

---

## 4. Platform-Specific Implementation Summary

### 4.1. 🍏 iOS Setup (Xcode)

- **Entitlements:** Add the **'Sign In with Apple' capability** to the target in **Signing & Capabilities**.
- **Provisioning:** Ensure the provisioning profile used for the app is updated to include the new capability.

### 4.2. 🤖 Android/Web Setup (Web Authentication)

- **Domain Requirement:** The domain for the **Redirect URI** must be a **registered HTTPS domain**. Localhost/IP addresses are not permitted.
- **Flutter Code:** When triggering the sign-in flow on non-iOS platforms, the package implementation must explicitly pass the **Service ID** as the `clientID` to initiate the web flow.

### 4.3. Flutter Implementation Snippet

The following Dart code uses the Service ID for both flows (it is only used as the `clientID` in the web flow, while the native flow uses the App ID entitlement configured in Xcode).

```dart
SignInWithAppleButton(
  onPressed: () async {
    final credential = await SignInWithApple.getAppleIDCredential(
      // Configure scopes to request user data
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      // Required for Android/Web flow (Service ID configured in the Portal)
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: 'YOUR_SERVICE_ID',
        redirectUri: Uri.parse('YOUR_REDIRECT_URI'),
      ),
    );

    // Send credential.authorizationCode and credential.identityToken to your backend
    // The backend handles the Token Exchange or Token Verification based on the platform.

    return credential;
  },
);
```
