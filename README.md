# iOS Password Manager

A secure, feature-rich password manager built with SwiftUI for iOS and iPadOS. This app provides end-to-end encryption, biometric authentication, seamless synchronization with web APIs, and comprehensive accessibility support following WCAG 2.1 AA guidelines.

## Features

### 🔒 Security
- **Master Password Protection**: Secure your vault with a master password
- **Biometric Authentication**: Support for Face ID and Touch ID
- **End-to-End Encryption**: Local SQLite database encrypted with SQLCipher
- **Secure Storage**: Master password stored securely in iOS Keychain
- **Auto-Lock**: Configurable timeout for automatic locking

### 📱 User Experience
- **Native SwiftUI Interface**: Modern, intuitive design
- **Responsive Design**: Optimized for both iPhone and iPad
- **Dark/Light Mode**: System appearance support
- **Search Functionality**: Quickly find passwords across all fields
- **Categories**: Organize passwords with customizable categories
- **Favorites**: Mark frequently used passwords as favorites

### ♿ Accessibility (WCAG 2.1 AA Compliant)
- **VoiceOver Support**: Complete screen reader compatibility with descriptive labels
- **Dynamic Type**: Full support for iOS system font size settings (including accessibility sizes)
- **High Contrast**: Adaptive colors for high contrast mode
- **Reduced Motion**: Respects iOS reduce motion preferences
- **Keyboard Navigation**: Full keyboard and assistive technology support
- **Semantic Structure**: Proper heading hierarchy and content grouping
- **Audio Feedback**: VoiceOver announcements for user actions and state changes
- **Minimum Tap Targets**: All interactive elements meet 44pt minimum size requirement
- **Focus Management**: Logical focus order and clear visual indicators
- **Error Handling**: Accessible error messages and recovery guidance

### 🔧 Password Management
- **Password Generator**: Create strong, customizable passwords
- **Password Strength Analysis**: Real-time feedback on password security
- **Auto-Fill Integration**: Seamless integration with iOS AutoFill
- **Clipboard Management**: Auto-clear clipboard for security
- **Import/Export**: Backup and restore your data

### ☁️ Synchronization
- **API Integration**: Sync with web API endpoints using Alamofire
- **Conflict Resolution**: Smart merging of local and remote changes
- **Auto-Sync**: Configurable automatic synchronization
- **Offline Support**: Full functionality without internet connection

## Architecture

### Core Components

#### Models
- **DataModels.swift**: Core data structures (Password, Category, User)
- **APIModels.swift**: API communication models with JSON serialization

#### Services
- **AuthenticationService**: Manages user authentication and biometrics
- **PasswordService**: Handles password CRUD operations and search
- **DatabaseService**: SQLite/SQLCipher database management
- **APIService**: Network communication with Alamofire
- **CryptoService**: Encryption, password generation, and strength analysis
- **KeychainService**: Secure storage using iOS Keychain
- **SettingsService**: App configuration and preferences

#### Views
- **LoginView**: Master password and biometric authentication
- **PasswordListView**: Main password listing with search and filters
- **AddEditPasswordView**: Password creation and editing forms
- **PasswordDetailView**: Detailed password information and actions
- **SettingsView**: App configuration and preferences
- **CategoryViews**: Category management interface
- **GeneratorView**: Password generation tools

### Database Schema

The app uses SQLCipher for encrypted local storage with the following tables:

```sql
-- Categories table
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at DATETIME NOT NULL,
    modified_at DATETIME NOT NULL,
    synced_at DATETIME
);

-- Passwords table
CREATE TABLE passwords (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    username TEXT NOT NULL,
    password TEXT NOT NULL,
    website TEXT,
    notes TEXT,
    category_id TEXT,
    is_favorite BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    modified_at DATETIME NOT NULL,
    synced_at DATETIME,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- User table
CREATE TABLE user (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    master_password_hash TEXT NOT NULL,
    biometric_enabled BOOLEAN NOT NULL DEFAULT 0,
    sync_enabled BOOLEAN NOT NULL DEFAULT 0,
    last_sync_at DATETIME
);
```

## API Integration

The app is designed to sync with a web API that exposes the following endpoints:

### Authentication
- `POST /api/auth/login` - User authentication
- `POST /api/auth/logout` - Session termination

### Sync Operations
- `POST /api/sync` - Bidirectional data synchronization
- `GET /api/health` - Connection testing

### Individual Operations
- `GET /api/passwords` - Fetch all passwords
- `POST /api/passwords` - Create password
- `PUT /api/passwords/{id}` - Update password
- `DELETE /api/passwords/{id}` - Delete password
- `GET /api/categories` - Fetch all categories
- `POST /api/categories` - Create category
- `PUT /api/categories/{id}` - Update category
- `DELETE /api/categories/{id}` - Delete category

### API Models

```swift
struct SyncRequest: Codable {
    let passwords: [APIPassword]
    let categories: [APICategory]
    let lastSyncAt: String?
}

struct SyncResponse: Codable {
    let passwords: [APIPassword]
    let categories: [APICategory]
    let serverTimestamp: String
}
```

## Security Features

### Encryption
- **Database**: AES-256 encryption via SQLCipher
- **Master Password**: SHA-256 hashing with salt
- **Data Transit**: HTTPS for all API communications
- **Local Storage**: iOS Keychain for sensitive data

### Authentication
- **Multi-Factor**: Master password + biometric options
- **Session Management**: Automatic timeout and manual lock
- **Secure Defaults**: Biometric authentication disabled by default

### Privacy
- **No Telemetry**: No user data collection or analytics
- **Local First**: All data stored locally by default
- **Clipboard Security**: Automatic clipboard clearing
- **Screen Protection**: Content hidden in app switcher

## Installation

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0 or later
- iPad OS 16.0 or later

### Dependencies
The app uses Swift Package Manager for dependency management:

```swift
dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.1"),
    .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
    .package(url: "https://github.com/sqlcipher/sqlcipher.git", from: "4.5.5")
]
```

### Build Instructions

1. Clone the repository:
```bash
git clone https://github.com/dotnetappdev/iospasswordmanager.git
cd iospasswordmanager
```

2. Open the project in Xcode:
```bash
open PasswordManagerApp.xcodeproj
```

3. Select your target device or simulator

4. Build and run the project (⌘+R)

### Configuration

#### API Setup
1. Open the app and navigate to Settings > API Configuration
2. Enter your API URL and API key
3. Test the connection to verify connectivity
4. Enable sync to start automatic synchronization

#### Biometric Authentication
1. Go to Settings > Security
2. Enable Face ID or Touch ID
3. Complete the biometric authentication setup

## Usage

### First Run
1. Launch the app
2. Create a new account with email and master password
3. Configure biometric authentication (optional)
4. Set up API synchronization (optional)

### Adding Passwords
1. Tap the "+" button in the password list
2. Fill in the required information
3. Use the password generator for secure passwords
4. Assign to a category (optional)
5. Save the password

### Organizing with Categories
1. Navigate to the Categories tab
2. Create new categories with custom icons and colors
3. Assign passwords to categories for better organization
4. Filter passwords by category

### Password Generation
1. Use the Generator tab for standalone password creation
2. Customize length and character types
3. Copy generated passwords to clipboard
4. View real-time password strength analysis

### Synchronization
1. Configure API settings in Settings
2. Enable auto-sync for automatic updates
3. Manual sync available via pull-to-refresh or settings
4. Monitor sync status in settings

## Device Compatibility

### iPhone
- All iPhone models supporting iOS 16.0+
- Optimized for various screen sizes
- Portrait and landscape orientations
- Touch ID and Face ID support

### iPad
- All iPad models supporting iPadOS 16.0+
- Split-view sidebar navigation
- Larger form factors for easier data entry
- Multi-column layouts for better space utilization
- External keyboard support

### Responsive Design Features
- Adaptive layouts based on screen size
- Dynamic font scaling
- Orientation-aware interface
- Accessibility compliance
- VoiceOver support

## Security Best Practices

### For Users
1. Use a strong, unique master password
2. Enable biometric authentication
3. Set appropriate auto-lock timeout
4. Regularly sync data to prevent loss
5. Enable clipboard auto-clear

### For Developers
1. Database encryption is mandatory
2. Master passwords are never stored in plaintext
3. API communications use HTTPS only
4. Sensitive data uses iOS Keychain
5. App implements certificate pinning (recommended)

## Accessibility Testing

### VoiceOver Testing
The app has been thoroughly tested with VoiceOver to ensure screen reader compatibility:

1. **Enable VoiceOver**: Settings > Accessibility > VoiceOver
2. **Test Navigation**: 
   - All UI elements are properly labeled
   - Logical reading order is maintained
   - Interactive elements have appropriate traits
   - Screen changes are announced
3. **Test Functionality**:
   - Login with master password and biometrics
   - Browse password list with search and filtering
   - Create, edit, and delete passwords
   - Access all settings and configuration options

### Dynamic Type Testing
Test with various text sizes to ensure proper scaling:

1. **Settings > Display & Brightness > Text Size**
2. **Settings > Accessibility > Display & Text Size > Larger Text**
3. Test with sizes from smallest to largest accessibility sizes
4. Verify all text remains readable and UI layouts adapt properly

### High Contrast Testing
1. **Enable High Contrast**: Settings > Accessibility > Display & Text Size > Increase Contrast
2. Verify all text maintains sufficient contrast ratios
3. Test both light and dark modes with high contrast enabled

### Reduced Motion Testing
1. **Enable Reduce Motion**: Settings > Accessibility > Motion > Reduce Motion
2. Verify animations are reduced or eliminated appropriately
3. Ensure transitions don't rely solely on motion for information

### Keyboard Navigation Testing
1. Connect external keyboard to iPad
2. Test tab navigation through all interface elements
3. Verify all actions can be performed via keyboard
4. Check focus indicators are clearly visible

### Accessibility Inspector
Use Xcode's Accessibility Inspector to validate:
- Accessibility labels and hints
- Element hierarchy and grouping
- Touch target sizes (minimum 44pt)
- Color contrast ratios
- Missing accessibility information

## Troubleshooting

### Common Issues

#### Sync Failures
- Verify API URL and key configuration
- Check internet connectivity
- Confirm server endpoint availability
- Review API logs for error details

#### Biometric Authentication
- Ensure device supports Face ID/Touch ID
- Verify biometric data is enrolled in device settings
- Check app permissions for biometric access

#### Database Issues
- If database becomes corrupted, app will recreate it
- Import backup data if available
- Contact support for data recovery assistance

### Debug Mode
Enable debug logging by setting the environment variable:
```
DEBUG_LOGGING=1
```

## Contributing

This project follows standard iOS development practices:

1. Fork the repository
2. Create a feature branch
3. Implement changes with proper testing
4. Submit a pull request with detailed description
5. Ensure all tests pass and code review is completed

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Include unit tests for new features
- Document public APIs with Swift documentation

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Support

For issues, feature requests, or questions:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include device information and iOS version
4. Provide steps to reproduce any bugs

## Roadmap

### Planned Features
- [ ] Apple Watch companion app
- [ ] Siri Shortcuts integration
- [ ] Advanced password policies
- [ ] Secure sharing capabilities
- [ ] Additional export formats
- [ ] Enhanced search filters
- [ ] Password history tracking
- [ ] Breach monitoring integration

### Future Considerations
- macOS companion app
- Browser extension
- Enterprise features
- Advanced analytics
- Multi-vault support
