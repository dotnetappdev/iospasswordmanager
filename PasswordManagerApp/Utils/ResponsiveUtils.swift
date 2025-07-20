import SwiftUI

// MARK: - Device Type Detection
extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - Screen Size Utilities
struct ScreenSize {
    static let width = UIScreen.main.bounds.size.width
    static let height = UIScreen.main.bounds.size.height
    static let maxLength = max(ScreenSize.width, ScreenSize.height)
    static let minLength = min(ScreenSize.width, ScreenSize.height)
    
    static var isSmallDevice: Bool {
        return maxLength < 812.0
    }
    
    static var isMediumDevice: Bool {
        return maxLength >= 812.0 && maxLength < 896.0
    }
    
    static var isLargeDevice: Bool {
        return maxLength >= 896.0
    }
}

// MARK: - Responsive Layout Utilities
struct ResponsiveHStack<Content: View>: View {
    let content: Content
    let spacing: CGFloat
    let threshold: CGFloat
    
    init(threshold: CGFloat = 600, spacing: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.threshold = threshold
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > threshold {
                HStack(spacing: spacing) {
                    content
                }
            } else {
                VStack(spacing: spacing) {
                    content
                }
            }
        }
    }
}

// MARK: - Adaptive Columns
struct AdaptiveGrid<Content: View>: View {
    let content: Content
    let minItemWidth: CGFloat
    let spacing: CGFloat
    
    init(minItemWidth: CGFloat = 300, spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.minItemWidth = minItemWidth
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columns = max(1, Int(geometry.size.width / minItemWidth))
            let adaptedColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
            
            LazyVGrid(columns: adaptedColumns, spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - Device-Specific Modifiers
extension View {
    func adaptiveFont(iPhone: Font, iPad: Font) -> some View {
        self.font(UIDevice.isIPad ? iPad : iPhone)
    }
    
    func adaptivePadding(iPhone: CGFloat, iPad: CGFloat) -> some View {
        self.padding(UIDevice.isIPad ? iPad : iPhone)
    }
    
    func adaptiveHorizontalPadding(iPhone: CGFloat, iPad: CGFloat) -> some View {
        self.padding(.horizontal, UIDevice.isIPad ? iPad : iPhone)
    }
    
    func adaptiveVerticalPadding(iPhone: CGFloat, iPad: CGFloat) -> some View {
        self.padding(.vertical, UIDevice.isIPad ? iPad : iPhone)
    }
    
    func adaptiveFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        GeometryReader { geometry in
            self.frame(
                width: width ?? geometry.size.width,
                height: height ?? geometry.size.height
            )
        }
    }
}

// MARK: - Orientation Detection
struct OrientationInfo {
    static var isLandscape: Bool {
        UIDevice.current.orientation.isLandscape
    }
    
    static var isPortrait: Bool {
        UIDevice.current.orientation.isPortrait
    }
}

// MARK: - Safe Area Utilities
extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    var safeAreaInsets: UIEdgeInsets {
        keyWindow?.safeAreaInsets ?? .zero
    }
}

// MARK: - Dynamic Type Support
extension View {
    func dynamicTypeSize(min: DynamicTypeSize = .small, max: DynamicTypeSize = .accessibility3) -> some View {
        self.dynamicTypeSize(min...max)
    }
}

// MARK: - Color Extensions for Dark Mode
extension Color {
    static let adaptiveBackground = Color(UIColor.systemBackground)
    static let adaptiveSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let adaptiveTertiaryBackground = Color(UIColor.tertiarySystemBackground)
    static let adaptivePrimary = Color(UIColor.label)
    static let adaptiveSecondary = Color(UIColor.secondaryLabel)
    static let adaptiveTertiary = Color(UIColor.tertiaryLabel)
}

// MARK: - Responsive Navigation
struct ResponsiveNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if UIDevice.isIPad {
            NavigationSplitView {
                // Sidebar content would go here
                EmptyView()
            } detail: {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }
}

// MARK: - Keyboard Responsive
struct KeyboardResponsive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                keyboardHeight = keyboardFrame.height
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
    }
}

extension View {
    func keyboardResponsive() -> some View {
        self.modifier(KeyboardResponsive())
    }
}

// MARK: - App State Management
class AppStateManager: ObservableObject {
    @Published var currentDeviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
    @Published var isKeyboardVisible: Bool = false
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.currentDeviceOrientation = UIDevice.current.orientation
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isKeyboardVisible = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}