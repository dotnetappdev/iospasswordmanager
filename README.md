# iOS Password Manager

A secure, feature-rich password manager for iOS that prioritizes security and ease of use.

## Features

### 🔐 **Master Key Authentication**
- Primary authentication method using a user-defined master key
- Secure validation with minimum 8-character requirement
- First-time setup automatically stores master key securely

### 📱 **QR Code Integration**
- Scan QR codes from desktop applications for seamless authentication
- Built-in camera integration with proper permissions
- Visual feedback and guidance for successful scanning

### 👤 **Biometric Authentication**
- Face ID and Touch ID support for quick access
- User choice prompt for enabling biometric authentication
- Fallback to master key if biometric authentication fails

### 🔒 **Military-Grade Encryption**
- AES-GCM encryption using Apple's CryptoKit framework
- SHA256 key derivation from master key
- All passwords encrypted before storage

### 🏦 **Secure iOS Keychain Storage**
- iOS Keychain services for secure data storage
- Biometric-protected keychain entries when available
- Device-specific storage that survives app reinstalls

### 📋 **Copy to Clipboard**
- One-tap clipboard functionality for all password fields
- Copy titles, usernames, passwords, and websites
- Quick access without revealing sensitive information

## Project Structure

```
iOSPasswordManager/
├── App.swift                 # Main app entry point
├── Views/
│   ├── ContentView.swift     # Main app container and password list
│   ├── LoginView.swift       # Authentication interface
│   └── QRScannerView.swift   # QR code scanning functionality
├── Models/
│   └── PasswordManager.swift # Core password management logic
├── Services/
│   ├── KeychainService.swift # Secure storage operations
│   └── BiometricAuth.swift   # Biometric authentication handling
└── Assets.xcassets/          # App icons and visual assets
```

## Security Features

### Encryption
- **Algorithm**: AES-GCM with 256-bit keys
- **Key Derivation**: SHA256 hash of master key
- **Data Protection**: All sensitive data encrypted before storage

### Authentication
- **Master Key**: Required for all access, minimum 8 characters
- **Biometric**: Optional Face ID/Touch ID for convenience
- **QR Codes**: Secure authentication via desktop app integration

### Storage
- **iOS Keychain**: Leverages iOS secure storage mechanisms
- **Device Binding**: Data tied to specific device hardware
- **Access Control**: Biometric and passcode protection available

## Building and Running

### Requirements
- Xcode 15.0 or later
- iOS 15.0+ deployment target
- Swift 5.9+

### Setup
1. Open `iOSPasswordManager.xcodeproj` in Xcode
2. Select your development team in project settings
3. Update bundle identifier if needed
4. Build and run on device or simulator

### Permissions
The app requires the following permissions:
- **Camera**: For QR code scanning (`NSCameraUsageDescription`)
- **Face ID**: For biometric authentication (`NSFaceIDUsageDescription`)

## Usage

### First Launch
1. Enter a secure master key (minimum 8 characters)
2. Choose whether to enable biometric authentication
3. Start adding passwords to your secure vault

### Daily Use
1. Authenticate with master key, Face ID, or Touch ID
2. View your password list with hidden passwords
3. Tap any password entry to view details
4. Use clipboard buttons to copy any field instantly

### QR Code Authentication
1. Open the desktop password manager
2. Generate a QR code for mobile authentication
3. Tap "Scan QR Code" in the iOS app
4. Point camera at the QR code to authenticate

## Security Best Practices

### Master Key
- Use a strong, unique master key
- Don't reuse passwords from other accounts
- Consider using a passphrase with multiple words

### Biometric Authentication
- Enable Face ID/Touch ID for convenience while maintaining security
- Understand that biometric data never leaves your device

### General Security
- Keep iOS updated to the latest version
- Don't jailbreak your device
- Use device passcode protection
- Enable automatic app lock when leaving the app

## Architecture

### SwiftUI + MVVM
- Modern SwiftUI interface for native iOS experience
- ObservableObject pattern for reactive state management
- Separation of concerns with dedicated service layers

### Security-First Design
- No network communication - fully offline operation
- Encryption before storage - no plaintext passwords
- iOS security frameworks - leveraging Apple's security infrastructure

## Compatibility

- **iOS Version**: 15.0+
- **Devices**: iPhone and iPad
- **Orientation**: Portrait and landscape support
- **Accessibility**: VoiceOver and Dynamic Type support

This password manager prioritizes security while maintaining ease of use, providing a robust solution for managing passwords on iOS devices.
