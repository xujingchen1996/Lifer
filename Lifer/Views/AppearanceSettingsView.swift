//
//  AppearanceSettingsView.swift
//  Lifer
//
//  外观设置页面 - 支持主题模式和自定义主题颜色
//

import SwiftUI

/// 主题模式枚举
enum ThemeMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
}

/// 外观设置视图
struct AppearanceSettingsView: View {
    @AppStorage("themeMode") private var themeModeRawValue = "system"
    @ObservedObject private var themeManager = ThemeManager.shared

    private var themeMode: ThemeMode {
        get { ThemeMode(rawValue: themeModeRawValue) ?? .system }
        nonmutating set { themeModeRawValue = newValue.rawValue }
    }

    var body: some View {
        Form {
            // 主题模式选择
            Section("主题模式") {
                ForEach(ThemeMode.allCases, id: \.rawValue) { mode in
                    HStack {
                        Text(mode.displayName)
                        Spacer()
                        if themeMode == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.currentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            themeMode = mode
                        }
                    }
                }
            }

            // 主题颜色选择
            Section("主题颜色") {
                HStack {
                    Text("选择颜色")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: themeManager.currentColorHex) ?? .blue },
                        set: { newColor in
                            if let hex = newColor.toHex() {
                                themeManager.setColor(hex)
                            }
                        }
                    ))
                    .labelsHidden()
                }

                // 预设颜色快捷选项
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(presetColors, id: \.self) { colorHex in
                        let color = Color(hex: colorHex) ?? .blue
                        let isSelected = themeManager.currentColorHex == colorHex
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                themeManager.setColor(colorHex)
                            }
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                )
                                .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: isSelected ? 6 : 0)
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("外观")
    }

    // 预设颜色
    private var presetColors: [String] {
        [
            "#007AFF",  // 蓝色
            "#5856D6",  // 紫色
            "#FF2D55",  // 粉色
            "#FF9500",  // 橙色
            "#FFCC00",  // 黄色
            "#34C759",  // 绿色
            "#32D74B",  // 青色
            "#AF52DE",  // 靛蓝
            "#8E8E93",  // 灰色
            "#FF3B30",  // 红色
            "#FF6482",  // 深粉
            "#64D2FF"   // 浅蓝
        ]
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
