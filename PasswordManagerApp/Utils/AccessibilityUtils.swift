import SwiftUI

// MARK: - Accessibility Constants
struct AccessibilityConstants {
    
    // MARK: - Common Labels
    struct Labels {
        static let close = "Close"
        static let back = "Back"
        static let next = "Next"
        static let done = "Done"
        static let cancel = "Cancel"
        static let save = "Save"
        static let edit = "Edit"
        static let delete = "Delete"
        static let add = "Add"
        static let search = "Search"
        static let filter = "Filter"
        static let sort = "Sort"
        static let copy = "Copy"
        static let paste = "Paste"
        static let share = "Share"
        static let settings = "Settings"
        static let refresh = "Refresh"
        static let menu = "Menu"
        static let more = "More options"
    }
    
    // MARK: - Password Manager Specific
    struct PasswordManager {
        static let passwordField = "Password"
        static let usernameField = "Username"
        static let emailField = "Email"
        static let websiteField = "Website"
        static let notesField = "Notes"
        static let titleField = "Title"
        static let categoryField = "Category"
        
        static let showPassword = "Show password"
        static let hidePassword = "Hide password"
        static let copyPassword = "Copy password"
        static let copyUsername = "Copy username"
        static let generatePassword = "Generate password"
        
        static let favoriteButton = "Mark as favorite"
        static let unfavoriteButton = "Remove from favorites"
        
        static let passwordStrengthWeak = "Password strength: Weak"
        static let passwordStrengthMedium = "Password strength: Medium"
        static let passwordStrengthStrong = "Password strength: Strong"
        static let passwordStrengthVeryStrong = "Password strength: Very Strong"
    }
    
    // MARK: - Navigation
    struct Navigation {
        static let passwordsTab = "Passwords"
        static let favoritesTab = "Favorites"
        static let categoriesTab = "Categories"
        static let generatorTab = "Password Generator"
        static let settingsTab = "Settings"
        
        static let passwordsList = "Passwords list"
        static let favoritesList = "Favorites list"
        static let categoriesList = "Categories list"
    }
    
    // MARK: - Hints
    struct Hints {
        static let tapToEdit = "Double tap to edit"
        static let tapToCopy = "Double tap to copy to clipboard"
        static let tapToReveal = "Double tap to reveal password"
        static let tapToToggleFavorite = "Double tap to toggle favorite status"
        static let tapToShowOptions = "Double tap to show options"
        static let searchPasswordsHint = "Enter text to search through your passwords"
        static let masterPasswordHint = "Enter your master password to unlock the app"
        static let biometricAuthHint = "Use Face ID or Touch ID to unlock the app"
    }
    
    // MARK: - Announcements
    struct Announcements {
        static let passwordCopied = "Password copied to clipboard"
        static let usernameCopied = "Username copied to clipboard"
        static let passwordSaved = "Password saved successfully"
        static let passwordDeleted = "Password deleted"
        static let addedToFavorites = "Added to favorites"
        static let removedFromFavorites = "Removed from favorites"
        static let loginSuccessful = "Login successful"
        static let loginFailed = "Login failed"
        static let passwordGenerated = "New password generated"
        static let dataLoaded = "Passwords loaded"
        static let syncCompleted = "Sync completed"
        static let errorOccurred = "An error occurred"
    }
}

// MARK: - Accessibility Helper Extensions
extension View {
    
    /// Add accessibility label and hint in one call
    func accessibilityLabelAndHint(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    /// Add accessibility for buttons with proper traits
    func accessibilityButton(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add accessibility for text fields
    func accessibilityTextField(_ label: String, hint: String? = nil, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isSearchField)
    }
    
    /// Add accessibility for headings
    func accessibilityHeading(_ label: String? = nil) -> some View {
        self
            .accessibilityLabel(label ?? "")
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Add accessibility for list items
    func accessibilityListItem(_ label: String, hint: String? = nil, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add accessibility for toggle controls
    func accessibilityToggle(_ label: String, isOn: Bool, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add accessibility for secure content
    func accessibilitySecure(_ label: String, isRevealed: Bool = false) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isRevealed ? "Revealed" : "Hidden")
            .accessibilityHint(isRevealed ? AccessibilityConstants.Hints.tapToEdit : AccessibilityConstants.Hints.tapToReveal)
            .accessibilityAddTraits(.isButton)
    }
    
    /// Group related accessibility elements
    func accessibilityGroup() -> some View {
        self.accessibilityElement(children: .combine)
    }
    
    /// Announce changes to VoiceOver users
    func announceAccessibilityChange(_ announcement: String) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }
    
    /// Make element focusable for VoiceOver
    func accessibilityFocusable(_ isFocusable: Bool = true) -> some View {
        self.accessibilityElement(children: isFocusable ? .contain : .ignore)
    }
    
    /// Add accessibility identifier for testing
    func accessibilityId(_ identifier: String) -> some View {
        self.accessibilityIdentifier(identifier)
    }
}

// MARK: - Dynamic Font Extensions
extension View {
    
    /// Apply scalable font that respects user's accessibility settings
    func scalableFont(_ textStyle: Font.TextStyle, design: Font.Design = .default, weight: Font.Weight = .regular) -> some View {
        self.font(.system(textStyle, design: design, weight: weight))
    }
    
    /// Apply scalable font with custom size that still scales
    func scalableFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.font(.system(size: size, weight: weight, design: design))
    }
    
    /// Ensure minimum tap target size for accessibility (44pt)
    func accessibleTapTarget(minSize: CGFloat = 44) -> some View {
        self.frame(minWidth: minSize, minHeight: minSize)
    }
}

// MARK: - Color Accessibility Extensions
extension Color {
    
    /// High contrast colors for better accessibility
    struct Accessible {
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(UIColor.tertiaryLabel)
        
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
        
        static let accent = Color.accentColor
        static let destructive = Color.red
        static let success = Color.green
        static let warning = Color.orange
        
        // High contrast alternatives
        static let highContrastPrimary = Color.black
        static let highContrastSecondary = Color.white
        static let highContrastAccent = Color.blue
    }
    
    /// Check if high contrast is enabled and return appropriate color
    static func adaptiveColor(normal: Color, highContrast: Color) -> Color {
        return UIAccessibility.isDarkerSystemColorsEnabled ? highContrast : normal
    }
}

// MARK: - Accessibility State Manager
class AccessibilityStateManager: ObservableObject {
    @Published var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published var isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
    @Published var isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    
    init() {
        setupAccessibilityNotifications()
    }
    
    private func setupAccessibilityNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Check if user prefers large text sizes
    var prefersLargeText: Bool {
        return preferredContentSizeCategory.isAccessibilityCategory
    }
    
    /// Check if animations should be reduced
    var shouldReduceAnimations: Bool {
        return isReduceMotionEnabled
    }
}