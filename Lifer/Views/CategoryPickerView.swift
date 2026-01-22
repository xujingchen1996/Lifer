//
//  CategoryPickerView.swift
//  Lifer
//
//  类别选择视图 - 支持预设类别和自定义类别
//

import SwiftUI

/// 类别选择视图
struct CategoryPickerView: View {
    // MARK: - Bindings
    @Binding var selectedCategory: Category
    @Binding var customCategoryName: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var showingCustomInput = false
    @State private var tempCustomName = ""

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 预设类别网格
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Category.presetCategories, id: \.self) { category in
                            categoryButton(category)
                        }
                    }
                    .padding(.horizontal)

                    // 自定义类别选项
                    customCategorySection
                }
                .padding(.vertical)
            }
            .navigationTitle("选择类别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCustomInput) {
                customCategoryInputSheet
            }
        }
    }

    // MARK: - Category Button

    private func categoryButton(_ category: Category) -> some View {
        Button(action: {
            selectedCategory = category
        }) {
            VStack(spacing: 8) {
                // 图标圆形背景
                ZStack {
                    Circle()
                        .fill(category.swiftUIColor.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(category.swiftUIColor)
                }

                // 类别名称
                Text(category.localizedName)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedCategory == category ? category.swiftUIColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedCategory == category ? category.swiftUIColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Category Section

    private var customCategorySection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingCustomInput = true
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 60, height: 60)

                        Image(systemName: Category.custom.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("自定义类别")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        if !customCategoryName.isEmpty {
                            Text(customCategoryName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("点击创建自定义类别")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if selectedCategory == .custom && !customCategoryName.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    // MARK: - Custom Category Input Sheet

    private var customCategoryInputSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text("自定义类别名称")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextField("例如: 写作、绘画...", text: $tempCustomName)
                        .font(.title3)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal)

                // 颜色选择 (未来可以添加)
                // TODO: 添加颜色选择器

                Spacer()
            }
            .padding(.top)
            .navigationTitle("自定义类别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingCustomInput = false
                        tempCustomName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if !tempCustomName.trimmingCharacters(in: .whitespaces).isEmpty {
                            customCategoryName = tempCustomName.trimmingCharacters(in: .whitespaces)
                            selectedCategory = .custom
                        }
                        showingCustomInput = false
                        tempCustomName = ""
                    }
                    .fontWeight(.semibold)
                    .disabled(tempCustomName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CategoryPickerView(
        selectedCategory: .constant(.reading),
        customCategoryName: .constant("")
    )
}
