import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var passwordService: PasswordService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var settingsService: SettingsService
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
        }
    }
    
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            PasswordListView()
                .tabItem {
                    Image(systemName: "key.fill")
                    Text("Passwords")
                }
                .tag(0)
            
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
                .tag(1)
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Categories")
                }
                .tag(2)
            
            GeneratorView()
                .tabItem {
                    Image(systemName: "wand.and.stars")
                    Text("Generator")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
    
    private var iPadLayout: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            Group {
                switch selectedTab {
                case 0:
                    PasswordListView()
                case 1:
                    FavoritesView()
                case 2:
                    CategoriesView()
                case 3:
                    GeneratorView()
                case 4:
                    SettingsView()
                default:
                    PasswordListView()
                }
            }
        }
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
                
                NavigationLink(destination: FavoritesView()) {
                    Label("Favorites", systemImage: "heart.fill")
                        .badge(passwordService.favoriteCount)
                }
                .tag(1)
                
                NavigationLink(destination: CategoriesView()) {
                    Label("Categories", systemImage: "folder.fill")
                        .badge(passwordService.categoryCount)
                }
                .tag(2)
            }
            
            Section("Tools") {
                NavigationLink(destination: GeneratorView()) {
                    Label("Password Generator", systemImage: "wand.and.stars")
                }
                .tag(3)
                
                NavigationLink(destination: SearchView()) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(5)
            }
            
            Section("Account") {
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
                
                Button(action: {
                    authService.logout()
                }) {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Password Manager")
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationService())
        .environmentObject(PasswordService())
        .environmentObject(SettingsService())
}