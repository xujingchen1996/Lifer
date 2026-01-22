//
//  CategoryPickerView.swift
//  Lifer
//
//  类别选择视图 - 支持预设类别、自定义类别、删除、排序
//

import SwiftUI
import SwiftData

/// 类别选择视图
struct CategoryPickerView: View {
    // MARK: - Bindings
    @Binding var selectedCategoryName: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - SwiftData
    @Query private var customCategories: [CustomCategory]
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var isEditMode = false
    @State private var showingAddCategory = false
    @State private var showingResetAlert = false
    @State private var deletedPresetCategories: Set<String> = []
    @State private var categoryOrder: [String] = []  // 存储类别名称的顺序
    @State private var draggedItem: CategoryDisplayItem?

    // MARK: - Computed Properties
    private var availableCategories: [CategoryDisplayItem] {
        var items: [CategoryDisplayItem] = []

        // 如果有自定义顺序，按顺序排列
        if !categoryOrder.isEmpty {
            var categoryMap: [String: CategoryDisplayItem] = [:]

            // 预设类别（排除已删除的）
            for category in ActivityCategory.allCases {
                if !deletedPresetCategories.contains(category.rawValue) {
                    let item = CategoryDisplayItem(category: category, customCategory: nil)
                    categoryMap[item.name] = item
                }
            }

            // 自定义类别
            for customCategory in customCategories {
                let item = CategoryDisplayItem(category: nil, customCategory: customCategory)
                categoryMap[item.name] = item
            }

            // 按自定义顺序返回
            for name in categoryOrder {
                if let item = categoryMap[name] {
                    items.append(item)
                }
            }

            // 添加新增的类别（不在顺序中的）
            for item in categoryMap.values {
                if !categoryOrder.contains(item.name) {
                    items.append(item)
                }
            }
        } else {
            // 预设类别（排除已删除的）
            for category in ActivityCategory.allCases {
                if !deletedPresetCategories.contains(category.rawValue) {
                    items.append(CategoryDisplayItem(category: category, customCategory: nil))
                }
            }

            // 自定义类别
            for customCategory in customCategories {
                items.append(CategoryDisplayItem(category: nil, customCategory: customCategory))
            }
        }

        return items
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 类别网格
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(availableCategories) { item in
                            if isEditMode {
                                editModeCategoryItem(item)
                            } else {
                                categoryButton(item)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, isEditMode ? 160 : 80) // 编辑模式需要更多空间
                }
                .padding(.vertical)

                // 底部按钮区域
                VStack(spacing: 12) {
                    if isEditMode {
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            Text("重置预设类别")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            isEditMode = false
                        }) {
                            Text("完成")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("添加类别")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle(isEditMode ? "编辑类别" : "选择类别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isEditMode {
                        Button("完成") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet()
            }
            .alert("重置预设类别", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    deletedPresetCategories.removeAll()
                }
            } message: {
                Text("将恢复所有预设类别，自定义类别不受影响。")
            }
        }
        .onAppear {
            loadDeletedPresets()
            loadCategoryOrder()
        }
    }

    // MARK: - Category Button (Normal Mode)

    private func categoryButton(_ item: CategoryDisplayItem) -> some View {
        let isSelected = selectedCategoryName == item.name
        let color = item.color
        let icon = item.icon

        return Button(action: {
            selectedCategoryName = item.name
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }

                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.5) {
                withAnimation {
                    isEditMode = true
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Item (Edit Mode)

    private func editModeCategoryItem(_ item: CategoryDisplayItem) -> some View {
        let color = item.color
        let icon = item.icon
        let index = availableCategories.firstIndex(where: { $0.id == item.id }) ?? 0

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            .opacity(draggedItem?.id == item.id ? 0.5 : 1.0)
            .scaleEffect(draggedItem?.id == item.id ? 1.1 : 1.0)

            Text(item.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)

            // 拖动指示器 + 删除按钮
            HStack(spacing: 12) {
                // 拖动手柄
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .frame(width: 20, height: 20)

                // 删除按钮
                Button(action: {
                    deleteCategory(item)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white).padding(4))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(draggedItem?.id == item.id ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onDrag {
            NSItemProvider(object: "\(index)" as NSString)
            draggedItem = item
            return NSItemProvider(object: "\(index)" as NSString)
        }
    }

    // MARK: - Drag and Drop (在 LazyVGrid 上添加)
    // 注意：网格拖动排序较复杂，这里使用简化方案
    // 点击上移/下移按钮来调整顺序

    // MARK: - Actions

    private func deleteCategory(_ item: CategoryDisplayItem) {
        withAnimation {
            if let category = item.category {
                // 删除预设类别（标记为已删除）
                deletedPresetCategories.insert(category.rawValue)
                saveDeletedPresets()
            } else if let customCategory = item.customCategory {
                // 删除自定义类别
                modelContext.delete(customCategory)
            }
            // 同时从顺序中移除
            categoryOrder.removeAll { $0 == item.name }
            saveCategoryOrder()
        }
    }

    private func loadDeletedPresets() {
        if let data = UserDefaults.standard.data(forKey: "deletedPresetCategories"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            deletedPresetCategories = decoded
        }
    }

    private func saveDeletedPresets() {
        if let encoded = try? JSONEncoder().encode(deletedPresetCategories) {
            UserDefaults.standard.set(encoded, forKey: "deletedPresetCategories")
        }
    }

    private func loadCategoryOrder() {
        if let data = UserDefaults.standard.data(forKey: "categoryOrder"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            categoryOrder = decoded
        } else {
            // 首次加载，初始化为默认顺序
            categoryOrder = availableCategories.map { $0.name }
            saveCategoryOrder()
        }
    }

    private func saveCategoryOrder() {
        if let encoded = try? JSONEncoder().encode(categoryOrder) {
            UserDefaults.standard.set(encoded, forKey: "categoryOrder")
        }
    }
}

// MARK: - CategoryDisplayItem

struct CategoryDisplayItem: Identifiable, Equatable {
    let id = UUID()
    let category: ActivityCategory?
    let customCategory: CustomCategory?

    var name: String {
        category?.rawValue ?? customCategory?.name ?? "未知"
    }

    var icon: String {
        category?.icon ?? customCategory?.icon ?? "star.fill"
    }

    var color: Color {
        if let category = category {
            return category.swiftUIColor
        }
        if let customCategory = customCategory {
            return customCategory.color
        }
        return .blue
    }

    static func == (lhs: CategoryDisplayItem, rhs: CategoryDisplayItem) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - AddCategorySheet

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "#5856D6"

    private let availableIcons = [
        "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        "moon.fill", "sun.max.fill", "cloud.fill", "snowflake",
        "book.fill", "pencil", "paintbrush.fill", "hammer.fill",
        "gamecontroller.fill", "music.note", "mic.fill", "headphones",
        "bicycle", "car.fill", "airplane", "rocket.fill",
        "phone.fill", "laptopcomputer", "desktopcomputer", "figure.walk"
    ]

    private let availableColors = [
        "#007AFF", "#5856D6", "#FF2D55", "#FF9500",
        "#FFCC00", "#34C759", "#32D74B", "#AF52DE",
        "#8E8E93", "#FF3B30", "#FF6482", "#64D2FF"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("类别名称") {
                    TextField("输入名称", text: $name)
                }

                Section("图标") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(Array(availableIcons.enumerated()), id: \.offset) { _, icon in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedIcon = icon
                                }
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : Color.primary)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedIcon == icon ? Color(hex: selectedColor) ?? .purple : Color.gray.opacity(0.15))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedIcon == icon ? (Color(hex: selectedColor) ?? .purple) : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("颜色") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(Array(availableColors.enumerated()), id: \.offset) { _, colorHex in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedColor = colorHex
                                }
                            }) {
                                let color = Color(hex: colorHex) ?? .purple
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == colorHex ? 4 : 0)
                                    )
                                    .shadow(color: selectedColor == colorHex ? color.opacity(0.4) : .clear, radius: selectedColor == colorHex ? 8 : 0)
                                    .scaleEffect(selectedColor == colorHex ? 1.15 : 1.0)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("添加类别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCategory()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveCategory() {
        let customCategory = CustomCategory(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            colorHex: selectedColor
        )
        modelContext.insert(customCategory)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    CategoryPickerView(selectedCategoryName: .constant("阅读"))
}
