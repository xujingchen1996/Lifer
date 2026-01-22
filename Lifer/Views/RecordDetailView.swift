//
//  RecordDetailView.swift
//  Lifer
//
//  记录详情页 - 显示完整记录信息，支持添加备注和心情
//

import SwiftUI
import SwiftData

/// 记录详情视图
struct RecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: TimerRecord

    @State private var note: String
    @State private var selectedMood: Mood?
    @State private var isEditing = false

    init(record: TimerRecord) {
        self.record = record
        _note = State(initialValue: record.note ?? "")
        _selectedMood = State(initialValue: record.mood)
    }

    var body: some View {
        Form {
            // 基本信息
            Section("活动信息") {
                    HStack {
                        Text("活动名称")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(record.activityName)
                            .foregroundColor(.primary)
                    }

                    if let category = record.category, let activityCategory = ActivityCategory.from(string: category) {
                        HStack {
                            Text("类别")
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: activityCategory.icon)
                                    .foregroundColor(activityCategory.swiftUIColor)
                                Text(activityCategory.localizedName)
                            }
                            .foregroundColor(.primary)
                        }
                    }

                    HStack {
                        Text("开始时间")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDate(record.startTime))
                            .foregroundColor(.primary)
                    }

                    if let endTime = record.endTime {
                        HStack {
                            Text("结束时间")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDate(endTime))
                                .foregroundColor(.primary)
                        }

                        HStack {
                            Text("总时长")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDuration(record.totalDuration))
                                .foregroundColor(.primary)
                        }
                    }
                }

                // 备注/感悟
                Section {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                        .onChange(of: note) { oldValue, newValue in
                            record.note = newValue.isEmpty ? nil : newValue
                            try? modelContext.save()
                        }
                } header: {
                    Text("备注 / 感悟")
                } footer: {
                    Text("记录你在这次活动中的想法和感悟")
                        .font(.caption)
                }

                // 心情选择
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Mood.allCases) { mood in
                            moodButton(mood)
                        }
                    }
                } header: {
                    Text("心情")
                } footer: {
                    Text("选择这次活动时的心情状态")
                        .font(.caption)
                }
            }
            .navigationTitle("记录详情")
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

    // MARK: - Mood Button

    private func moodButton(_ mood: Mood) -> some View {
        let isSelected = selectedMood == mood

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                if isSelected {
                    // 取消选择
                    selectedMood = nil
                    record.mood = nil
                } else {
                    selectedMood = mood
                    record.mood = mood
                }
                try? modelContext.save()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: mood.color)?.opacity(0.15) ?? Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: mood.iconName)
                        .font(.title2)
                        .foregroundColor(Color(hex: mood.color) ?? .gray)
                }
                .overlay(
                    Circle()
                        .stroke(Color(hex: mood.color) ?? .gray, lineWidth: isSelected ? 3 : 0)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(mood.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? Color(hex: mood.color) : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return "\(hours)小时 \(minutes)分钟 \(seconds)秒"
        } else if minutes > 0 {
            return "\(minutes)分钟 \(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecordDetailView(record: {
            let record = TimerRecord(activityName: "阅读")
            record.totalDuration = 1800
            record.endTime = Date()
            record.isActive = false
            return record
        }())
    }
}
