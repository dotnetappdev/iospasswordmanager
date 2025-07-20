import SwiftUI

struct AddEditCategoryView: View {
    @EnvironmentObject var passwordService: PasswordService
    @Environment(\.dismiss) private var dismiss
    
    let categoryToEdit: Category?
    
    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "blue"
    
    private let availableIcons = [
        "folder", "folder.fill", "briefcase", "briefcase.fill", 
        "house", "house.fill", "car", "car.fill",
        "creditcard", "creditcard.fill", "gamecontroller", "gamecontroller.fill",
        "desktopcomputer", "laptopcomputer", "iphone", "ipad",
        "globe", "envelope", "person", "person.fill",
        "heart", "heart.fill", "star", "star.fill",
        "lock", "lock.fill", "key", "key.fill",
        "shield", "shield.fill", "eye", "eye.fill"
    ]
    
    private let availableColors = [
        "blue", "red", "green", "orange", "purple", "pink",
        "yellow", "teal", "indigo", "mint", "cyan", "brown"
    ]
    
    init(category: Category? = nil) {
        self.categoryToEdit = category
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Information") {
                    TextField("Category Name", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : Color(selectedColor))
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Color(selectedColor) : Color(selectedColor).opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? .primary : .clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Preview") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .foregroundColor(Color(selectedColor))
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color(selectedColor).opacity(0.2))
                            .cornerRadius(8)
                        
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.headline)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(categoryToEdit == nil ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            loadCategoryData()
        }
    }
    
    private func loadCategoryData() {
        if let categoryToEdit = categoryToEdit {
            name = categoryToEdit.name
            selectedIcon = categoryToEdit.icon
            selectedColor = categoryToEdit.color
        }
    }
    
    private func saveCategory() {
        if let categoryToEdit = categoryToEdit {
            // Edit existing category
            var updatedCategory = categoryToEdit
            updatedCategory.update(name: name, icon: selectedIcon, color: selectedColor)
            passwordService.updateCategory(updatedCategory)
        } else {
            // Create new category
            let newCategory = Category(name: name, icon: selectedIcon, color: selectedColor)
            passwordService.addCategory(newCategory)
        }
        
        dismiss()
    }
}

#Preview {
    AddEditCategoryView()
        .environmentObject(PasswordService())
}