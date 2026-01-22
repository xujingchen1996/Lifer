//
//  ActivityCategory.swift
//  Lifer
//
//  活动类别枚举 - 预设类别
//

import SwiftUI

/// 活动类别枚举
enum ActivityCategory: String, CaseIterable, Codable {
    // 预设类别
    case sports = "运动"
    case reading = "阅读"
    case work = "工作"
    case study = "学习"
    case meditation = "冥想"
    case entertainment = "娱乐"   // 替代健身
    case writing = "写作"
    case coding = "编程"
    case music = "音乐"
    case shopping = "购物"        // 新增
    case gaming = "游戏"          // 新增
    case travel = "旅行"          // 新增
    case movie = "电影"           // 新增

    /// 类别对应的 SF Symbol 图标
    var icon: String {
        switch self {
        case .sports: return "figure.run"
        case .reading: return "book.fill"
        case .work: return "briefcase.fill"
        case .study: return "graduationcap.fill"
        case .meditation: return "sparkles"
        case .entertainment: return "tv.fill"
        case .writing: return "pencil"
        case .coding: return "keyboard"
        case .music: return "music.note"
        case .shopping: return "cart.fill"
        case .gaming: return "gamecontroller.fill"
        case .travel: return "airplane"
        case .movie: return "film.fill"
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
        case .entertainment: return "#FF2D55" // 粉色
        case .writing: return "#FFCC00"     // 黄色
        case .coding: return "#8E8E93"      // 灰色
        case .music: return "#FF3B30"       // 红色
        case .shopping: return "#FF9500"    // 橙色
        case .gaming: return "#5856D6"      // 靛蓝色
        case .travel: return "#32D74B"      // 青色
        case .movie: return "#FF3B30"       // 红色
        }
    }

    /// 类别对应的 SwiftUI Color
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }
}

// MARK: - ActivityCategory 扩展

extension ActivityCategory {
    /// 获取所有预设类别（就是全部，因为不再有自定义类别在 enum 中）
    static var presetCategories: [ActivityCategory] {
        allCases
    }

    /// 从字符串创建 ActivityCategory
    static func from(string: String) -> ActivityCategory? {
        return ActivityCategory(rawValue: string)
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
