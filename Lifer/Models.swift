//
//  Models.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Mood Enum
enum Mood: String, CaseIterable, Identifiable {
    case happy = "happy"
    case focused = "focused"
    case relaxed = "relaxed"
    case neutral = "neutral"
    case sad = "sad"
    case tired = "tired"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .happy: return "开心"
        case .focused: return "专注"
        case .relaxed: return "放松"
        case .neutral: return "平静"
        case .sad: return "难过"
        case .tired: return "疲惫"
        }
    }

    var iconName: String {
        switch self {
        case .happy: return "face.smiling.fill"
        case .focused: return "eyes.inverse"
        case .relaxed: return "zzz"
        case .neutral: return "face.dashed.fill"
        case .sad: return "heart.slash.fill"
        case .tired: return "bed.double.fill"
        }
    }

    var color: String {
        switch self {
        case .happy: return "#FFCC00"     // 黄色
        case .focused: return "#007AFF"   // 蓝色
        case .relaxed: return "#34C759"   // 绿色
        case .neutral: return "#8E8E93"   // 灰色
        case .sad: return "#5856D6"       // 紫色
        case .tired: return "#FF3B30"     // 红色
        }
    }
}

// MARK: - TimerRecord
@Model
class TimerRecord {
    var id: UUID
    var activityName: String
    var startTime: Date
    var endTime: Date?
    var totalDuration: TimeInterval
    var pauseIntervals: [PauseInterval]?
    var isActive: Bool
    var note: String?          // 备注/感悟
    var moodRawValue: String?  // 心情（存储 Mood.rawValue）
    var category: String?      // 类别名称

    // 间隔提醒相关字段
    var reminderInterval: TimeInterval?  // 提醒间隔（秒）
    var nextReminderTime: Date?          // 下次提醒时间
    var reminderEnabled: Bool = false    // 是否启用提醒

    init(activityName: String) {
        self.id = UUID()
        self.activityName = activityName
        self.startTime = Date()
        self.totalDuration = 0
        self.pauseIntervals = []
        self.isActive = true
        self.note = nil
        self.moodRawValue = nil
        self.category = nil
        self.reminderInterval = nil
        self.nextReminderTime = nil
        self.reminderEnabled = false
    }

    // 心情的便捷访问
    var mood: Mood? {
        get {
            guard let rawValue = moodRawValue else { return nil }
            return Mood(rawValue: rawValue)
        }
        set {
            moodRawValue = newValue?.rawValue
        }
    }
}

struct PauseInterval: Codable {
    var pauseTime: Date
    var resumeTime: Date?
}

@Model
class Activity {
    var id: UUID
    var name: String
    var color: String // 存储为HEX字符串
    var icon: String? // SF Symbol名称
    var records: [TimerRecord]?
    
    init(name: String, color: String = "#007AFF", icon: String? = nil) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.records = []
    }
}

@Model
class UserAchievement {
    var id: UUID
    var title: String
    var achievementDescription: String
    var iconName: String
    var isUnlocked: Bool
    var unlockDate: Date?
    var progress: Double // 0.0 - 1.0

    init(title: String, description: String, iconName: String) {
        self.id = UUID()
        self.title = title
        self.achievementDescription = description
        self.iconName = iconName
        self.isUnlocked = false
        self.progress = 0.0
    }
}

// MARK: - CustomCategory
@Model
class CustomCategory {
    var id: UUID
    var name: String          // 类别名称
    var icon: String          // SF Symbol 名称
    var colorHex: String      // 颜色 HEX 值
    var createdAt: Date

    init(name: String, icon: String = "star.fill", colorHex: String = "#5856D6") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
    }

    /// SwiftUI Color
    var color: Color {
        Color(hex: colorHex) ?? .purple
    }
}
