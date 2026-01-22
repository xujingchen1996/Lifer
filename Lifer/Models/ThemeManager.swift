//
//  ThemeManager.swift
//  Lifer
//
//  主题颜色管理 - 使用 ObservableObject 实现实时更新
//

import SwiftUI

/// 主题管理器 - 可观察对象
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("customColorHex") private var customColorHex: String = "#007AFF" {
        didSet {
            // 当颜色变化时发布更新
            objectWillChange.send()
        }
    }

    /// 获取当前主题颜色
    var currentColor: Color {
        if let hexColor = Color(hex: customColorHex) {
            return hexColor
        }
        return .blue
    }

    /// 获取当前主题颜色的 HEX 值
    var currentColorHex: String {
        customColorHex
    }

    /// 设置主题颜色
    func setColor(_ hex: String) {
        customColorHex = hex
    }

    private init() {}
}

/// View 扩展：应用主题颜色
extension View {
    /// 应用主题颜色到前景元素（文字、图标等）
    func themeForeground(themeManager: ThemeManager = .shared) -> some View {
        self.foregroundColor(themeManager.currentColor)
    }

    /// 应用主题颜色到背景
    func themeBackground(themeManager: ThemeManager = .shared, opacity: Double = 1.0) -> some View {
        self.background(themeManager.currentColor.opacity(opacity))
    }
}
