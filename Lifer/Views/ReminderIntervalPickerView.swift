//
//  ReminderIntervalPickerView.swift
//  Lifer
//
//  间隔提醒选择视图
//

import SwiftUI

/// 间隔提醒枚举
enum ReminderInterval: TimeInterval, CaseIterable, Identifiable {
    case none = 0
    case oneMinute = 60
    case twoMinutes = 120
    case fiveMinutes = 300
    case tenMinutes = 600
    case twentyMinutes = 1200
    case thirtyMinutes = 1800
    case oneHour = 3600
    case twoHours = 7200

    var id: TimeInterval { rawValue }

    var displayName: String {
        switch self {
        case .none: return "无"
        case .oneMinute: return "1分钟"
        case .twoMinutes: return "2分钟"
        case .fiveMinutes: return "5分钟"
        case .tenMinutes: return "10分钟"
        case .twentyMinutes: return "20分钟"
        case .thirtyMinutes: return "30分钟"
        case .oneHour: return "1小时"
        case .twoHours: return "2小时"
        }
    }

    var iconName: String? {
        switch self {
        case .none: return "bell.slash"
        case .oneMinute, .twoMinutes: return "bell"
        case .fiveMinutes, .tenMinutes: return "bell.badge"
        case .twentyMinutes, .thirtyMinutes: return "bell.badge.fill"
        case .oneHour, .twoHours: return "alarm"
        }
    }
}

/// 间隔提醒选择视图
struct ReminderIntervalPickerView: View {
    @Binding var selectedInterval: ReminderInterval
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(ReminderInterval.allCases) { interval in
                Button {
                    selectedInterval = interval
                } label: {
                    HStack {
                        if let iconName = interval.iconName {
                            Image(systemName: iconName)
                                .foregroundColor(.orange)
                                .frame(width: 30)
                        }

                        Text(interval.displayName)
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedInterval == interval {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("提醒间隔")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReminderIntervalPickerView(selectedInterval: .constant(.none))
    }
}
