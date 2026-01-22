//
//  Category.swift
//  Lifer
//
//  活动类别枚举 - 预设类别 + 自定义支持
//

import SwiftUI

/// 活动类别枚举
enum Category: String, CaseIterable, Codable {
    // 预设类别
    case sports = "运动"
    case reading = "阅读"
    case work = "工作"
    case study = "学习"
    case meditation = "冥想"
    case exercise = "健身"
    case writing = "写作"
    case coding = "编程"
    case music = "音乐"
    case custom = "自定义"

    /// 类别对应的 SF Symbol 图标
    var icon: String {
        switch self {
        case .sports: return "figure.run"
        case .reading: return "book.fill"
        case .work: return "briefcase.fill"
        case .study: return "graduationcap.fill"
        case .meditation: return "sparkles"
        case .exercise: return "figure.strengthtraining.trainer"
        case .writing: return "pencil"
        case .coding: return "keyboard"
        case .music: return "music.note"
        case .custom: return "star.fill"
        }
    }

    /// 类别对应的颜色 (HEX 格式)
    var color: String {
        switch self {
        case .sports: return "#34C759"      // 绿色
        case .reading: return "#FF9500"     // 橙色
        case .work: return "#007AFF"        // 蓝色
        case .study: return "#AF52DE"       // 紫色
        case .meditation: return "#32D74B"   // 青色
        case .exercise: return "#FF3B30"    // 红色
        case .writing: return "#FFCC00"     // 黄色
        case .coding: return "#8E8E93"      // 灰色
        case .music: return "#FF2D55"       // 粉色
        case .custom: return "#5856D6"      // 靛蓝色
        }
    }

    /// 类别对应的 SwiftUI Color
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }

    /// 是否为自定义类别
    var isCustom: Bool {
        self == .custom
    }
}

// MARK: - Category 扩展

extension Category {
    /// 获取所有非自定义类别
    static var presetCategories: [Category] {
        allCases.filter { !$0.isCustom }
    }

    /// 从字符串创建 Category (支持自定义类别名称)
    static func from(string: String) -> Category {
        // 首先尝试匹配预设类别
        if let category = Category(rawValue: string) {
            return category
        }
        // 如果不匹配，返回自定义类别
        return .custom
    }

    /// 获取本地化显示名称
    var localizedName: String {
        return rawValue
    }
}

// MARK: - Color HEX 扩展

extension Color {
    /// 从 HEX 字符串创建 Color
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }

    /// 转换为 HEX 字符串
    func toHex() -> String? {
        #if os(iOS)
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
        #else
        return nil
        #endif
    }
}
