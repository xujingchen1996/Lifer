//
//  LiferWidgetLiveActivity.swift
//  LiferWidget
//
//  Created by Tron Xu on 21/1/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

/// Lifer Live Activity Widget
///
/// 显示计时器在灵动岛和锁屏界面
struct LiferWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiferActivityAttributes.self) { context in
            // 锁屏/横幅 UI
            LockScreenLiveActivityView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            // 灵动岛 UI
            DynamicIsland {
                // 展开状态
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.attributes.iconName)
                            .foregroundColor(Color(hex: context.attributes.colorHex))
                            .font(.title3)
                        Text(context.attributes.activityName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(elapsedTimeString(from: context.state.elapsedTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(.primary)
                }
            } compactLeading: {
                // 紧凑模式 - 左侧
                Image(systemName: context.attributes.iconName)
                    .foregroundColor(Color(hex: context.attributes.colorHex))
                    .font(.caption)
            } compactTrailing: {
                // 紧凑模式 - 右侧
                Text(elapsedTimeString(from: context.state.elapsedTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            } minimal: {
                // 最小模式 - 只显示图标
                Image(systemName: context.attributes.iconName)
                    .foregroundColor(Color(hex: context.attributes.colorHex))
            }
            .widgetURL(URL(string: "lifer://timer"))
        }
    }
}

/// 锁屏 Live Activity 视图 - 文字拼色布局
struct LockScreenLiveActivityView: View {
    let attributes: LiferActivityAttributes
    let state: LiferActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 0) {
            // 上半部分 - 活动名称
            HStack {
                Image(systemName: attributes.iconName)
                    .font(.caption2)
                    .foregroundColor(nameColor)
                Text(attributes.activityName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(nameColor)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(background)

            // 下半部分 - 计时显示
            HStack {
                Spacer()
                Text(elapsedTimeString(from: state.elapsedTime))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(timerColor)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // 背景色：日间白色，夜间黑色
    private var background: Color {
        state.isDarkMode ? Color(white: 0.12) : Color(white: 0.98)
    }

    // 名称颜色：日间黑色，夜间活动颜色
    private var nameColor: Color {
        state.isDarkMode ? Color(hex: attributes.colorHex) : Color.black
    }

    // 计时颜色：日间黑色，夜间白色
    private var timerColor: Color {
        state.isDarkMode ? Color.white : Color.black
    }
}

/// 将秒数转换为时间字符串 (HH:MM:SS)
private func elapsedTimeString(from seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = Int(seconds) / 60 % 60
    let secs = Int(seconds) % 60

    if hours > 0 {
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Color Extension for HEX support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews

extension LiferActivityAttributes {
    fileprivate static var preview: LiferActivityAttributes {
        LiferActivityAttributes(
            activityName: "工作",
            iconName: "briefcase.fill",
            colorHex: "007AFF",
            startTime: Date()
        )
    }

    fileprivate static var previewGreen: LiferActivityAttributes {
        LiferActivityAttributes(
            activityName: "运动",
            iconName: "figure.run",
            colorHex: "34C759",
            startTime: Date()
        )
    }

    fileprivate static var previewRed: LiferActivityAttributes {
        LiferActivityAttributes(
            activityName: "学习",
            iconName: "book.fill",
            colorHex: "FF3B30",
            startTime: Date()
        )
    }
}

extension LiferActivityAttributes.ContentState {
    fileprivate static var running: LiferActivityAttributes.ContentState {
        LiferActivityAttributes.ContentState(
            elapsedTime: 3665, // 1:01:05
            isActive: true,
            startTime: Date().addingTimeInterval(-3665),
            lastUpdateTime: Date(),
            isDarkMode: false
        )
    }

    fileprivate static var runningDark: LiferActivityAttributes.ContentState {
        LiferActivityAttributes.ContentState(
            elapsedTime: 3665,
            isActive: true,
            startTime: Date().addingTimeInterval(-3665),
            lastUpdateTime: Date(),
            isDarkMode: true
        )
    }

    fileprivate static var paused: LiferActivityAttributes.ContentState {
        LiferActivityAttributes.ContentState(
            elapsedTime: 180, // 3:00
            isActive: false,
            startTime: Date().addingTimeInterval(-180),
            lastUpdateTime: Date(),
            isDarkMode: false
        )
    }
}

#Preview("Notification - Blue", as: .content, using: LiferActivityAttributes.preview) {
    LiferWidgetLiveActivity()
} contentStates: {
    LiferActivityAttributes.ContentState.running
    LiferActivityAttributes.ContentState.paused
}

#Preview("Notification - Green", as: .content, using: LiferActivityAttributes.previewGreen) {
    LiferWidgetLiveActivity()
} contentStates: {
    LiferActivityAttributes.ContentState.running
}

#Preview("Notification - Red", as: .content, using: LiferActivityAttributes.previewRed) {
    LiferWidgetLiveActivity()
} contentStates: {
    LiferActivityAttributes.ContentState.running
}
