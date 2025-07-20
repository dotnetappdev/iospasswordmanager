import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var passwordService: PasswordService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var accessibilityStateManager: AccessibilityStateManager
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onAppear {
            passwordService.loadData()
            UIAccessibility.post(notification: .screenChanged, argument: "Main application interface loaded")
        }
        .accessibilityElement(children: .contain)
    }
    
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            PasswordListView()
                .tabItem {
                    Image(systemName: "key.fill")
                        .accessibilityHidden(true)
                    Text(AccessibilityConstants.Navigation.passwordsTab)
                }
                .tag(0)
                .accessibilityLabel(AccessibilityConstants.Navigation.passwordsTab)
                .accessibilityHint("View and manage your saved passwords")
            
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                        .accessibilityHidden(true)
                    Text(AccessibilityConstants.Navigation.favoritesTab)
                }
                .tag(1)
                .accessibilityLabel(AccessibilityConstants.Navigation.favoritesTab)
                .accessibilityHint("View your favorite passwords")
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                        .accessibilityHidden(true)
                    Text(AccessibilityConstants.Navigation.categoriesTab)
                }
                .tag(2)
                .accessibilityLabel(AccessibilityConstants.Navigation.categoriesTab)
                .accessibilityHint("Organize passwords by categories")
            
            GeneratorView()
                .tabItem {
                    Image(systemName: "wand.and.stars")
                        .accessibilityHidden(true)
                    Text(AccessibilityConstants.Navigation.generatorTab)
                }
                .tag(3)
                .accessibilityLabel(AccessibilityConstants.Navigation.generatorTab)
                .accessibilityHint("Generate secure passwords")
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                        .accessibilityHidden(true)
                    Text(AccessibilityConstants.Navigation.settingsTab)
                }
                .tag(4)
                .accessibilityLabel(AccessibilityConstants.Navigation.settingsTab)
                .accessibilityHint("Configure app settings and preferences")
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { newTab in
            let tabNames = [
                AccessibilityConstants.Navigation.passwordsTab,
                AccessibilityConstants.Navigation.favoritesTab,
                AccessibilityConstants.Navigation.categoriesTab,
                AccessibilityConstants.Navigation.generatorTab,
                AccessibilityConstants.Navigation.settingsTab
            ]
            
            if newTab < tabNames.count {
                UIAccessibility.post(notification: .screenChanged, argument: "\(tabNames[newTab]) selected")
            }
        }
    }
    
    private var iPadLayout: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            Group {
                switch selectedTab {
                case 0:
                    PasswordListView()
                        .accessibilityLabel(AccessibilityConstants.Navigation.passwordsList)
                case 1:
                    FavoritesView()
                        .accessibilityLabel(AccessibilityConstants.Navigation.favoritesList)
                case 2:
                    CategoriesView()
                        .accessibilityLabel(AccessibilityConstants.Navigation.categoriesList)
                case 3:
                    GeneratorView()
                        .accessibilityLabel("Password generator")
                case 4:
                    SettingsView()
                        .accessibilityLabel("Settings")
                default:
                    PasswordListView()
                        .accessibilityLabel(AccessibilityConstants.Navigation.passwordsList)
                }
            }
        }
        .accessibilityLabel("Split view navigation")
    }
}

struct SidebarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var passwordService: PasswordService
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        List(selection: $selectedTab) {
            Section("Password Manager") {
                NavigationLink(destination: PasswordListView()) {
                    Label("All Passwords", systemImage: "key.fill")
                        .badge(passwordService.passwordCount)
                }
                .tag(0)
                .accessibilityButton(
                    "All Passwords, \(passwordService.passwordCount) items",
                    hint: "View all your saved passwords"
                )
                
                NavigationLink(destination: FavoritesView()) {
                    Label("Favorites", systemImage: "heart.fill")
                        .badge(passwordService.favoriteCount)
                }
                .tag(1)
                .accessibilityButton(
                    "Favorites, \(passwordService.favoriteCount) items",
                    hint: "View your favorite passwords"
                )
                
                NavigationLink(destination: CategoriesView()) {
                    Label("Categories", systemImage: "folder.fill")
                        .badge(passwordService.categoryCount)
                }
                .tag(2)
                .accessibilityButton(
                    "Categories, \(passwordService.categoryCount) items",
                    hint: "Browse password categories"
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Password Manager section")
            
            Section("Tools") {
                NavigationLink(destination: GeneratorView()) {
                    Label("Password Generator", systemImage: "wand.and.stars")
                }
                .tag(3)
                .accessibilityButton(
                    "Password Generator",
                    hint: "Generate secure passwords"
                )
                
                NavigationLink(destination: SearchView()) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(5)
                .accessibilityButton(
                    AccessibilityConstants.Labels.search,
                    hint: "Search through your passwords"
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Tools section")
            
            Section("Account") {
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
                .accessibilityButton(
                    AccessibilityConstants.Labels.settings,
                    hint: "Configure app settings"
                )
                
                Button(action: {
                    authService.logout()
                    UIAccessibility.post(notification: .announcement, argument: "Signed out successfully")
                }) {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
                .accessibilityButton(
                    "Sign Out",
                    hint: "Sign out of your account"
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Account section")
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Password Manager")
        .accessibilityHeading("Password Manager")
        .accessibilityLabel("Sidebar navigation")
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationService())
        .environmentObject(PasswordService())
        .environmentObject(SettingsService())
        .environmentObject(AccessibilityStateManager())
}