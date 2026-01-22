//
//  HistoryView.swift
//  Lifer
//
//  历史记录页面 - DatePicker + 返回今天按钮
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimerRecord.startTime, order: .forward) private var allRecords: [TimerRecord]
    @Query private var customCategories: [CustomCategory]
    @State private var selectedDate: Date = Date()
    @State private var viewMode: ViewMode = .date

    private var calendar = Calendar.current

    enum ViewMode {
        case date
        case category
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部视图切换按钮
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        viewMode = .date
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text("日期")
                    }
                    .font(.subheadline)
                    .foregroundColor(viewMode == .date ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(viewMode == .date ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }

                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        viewMode = .category
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                        Text("分类")
                    }
                    .font(.subheadline)
                    .foregroundColor(viewMode == .category ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(viewMode == .category ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))

            Divider()

            // 内容区域
            if viewMode == .date {
                dateModeView
            } else {
                categoryModeView
            }
        }
        .navigationTitle("历史记录")
    }

    // MARK: - 日期模式视图

    private var dateModeView: some View {
        VStack(spacing: 0) {
            // 日期选择器 + 返回今天按钮
            HStack {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                Spacer()

                if !calendar.isDate(selectedDate, inSameDayAs: Date()) {
                    Button("今天") {
                        withAnimation {
                            selectedDate = Date()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemBackground))

            Divider()

            // 记录列表
            let dayRecords = recordsForSelectedDate

            if dayRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("这一天没有记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(dayRecords) { record in
                            RecordRow(record: record, customCategories: customCategories)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - 分类模式视图 (macOS Finder 风格)

    @ViewBuilder
    private var categoryModeView: some View {
        let grouped = recordsForSelectedDateByCategory

        if grouped.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("今天还没有记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(grouped.keys.sorted(), id: \.self) { categoryName in
                        CategorySectionView(
                            categoryName: categoryName,
                            records: grouped[categoryName] ?? [],
                            customCategories: customCategories
                        )
                    }
                }
            }
        }
    }

    // MARK: - 计算属性

    /// 选中日期的所有记录
    private var recordsForSelectedDate: [TimerRecord] {
        allRecords.filter { record in
            calendar.isDate(record.startTime, inSameDayAs: selectedDate)
        }
    }

    /// 选中日期的记录按类别分组
    private var recordsForSelectedDateByCategory: [String: [TimerRecord]] {
        let dayRecords = recordsForSelectedDate
        return Dictionary(grouping: dayRecords) { record in
            record.category ?? "未分类"
        }
    }
}

// MARK: - 分类头部 (macOS Finder 风格)

struct CategoryHeader: View {
    let categoryName: String
    let records: [TimerRecord]
    let customCategories: [CustomCategory]

    var body: some View {
        HStack(spacing: 8) {
            // 类别图标
            if let category = ActivityCategory.from(string: categoryName) {
                // 预设分类
                Image(systemName: category.icon)
                    .foregroundColor(category.swiftUIColor)
                    .font(.caption)
            } else if let customCategory = customCategories.first(where: { $0.name == categoryName }) {
                // 自定义分类
                Image(systemName: customCategory.icon)
                    .foregroundColor(customCategory.color)
                    .font(.caption)
            } else {
                // 未分类
                Image(systemName: "star.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }

            Text(categoryName)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("(\(records.count))")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(totalDuration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemBackground))
    }

    private var totalDuration: String {
        let total = records.reduce(0) { $0 + $1.totalDuration }
        let hours = Int(total) / 3600
        let minutes = Int(total) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - 分类分组视图

struct CategorySectionView: View {
    let categoryName: String
    let records: [TimerRecord]
    let customCategories: [CustomCategory]

    var body: some View {
        VStack(spacing: 0) {
            // 类别头部
            CategoryHeader(categoryName: categoryName, records: records, customCategories: customCategories)

            // 该类别的记录列表
            VStack(spacing: 0) {
                ForEach(records) { record in
                    RecordRow(record: record, customCategories: customCategories)

                    if record.id != records.last?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - 记录行

struct RecordRow: View {
    let record: TimerRecord
    var customCategories: [CustomCategory] = []

    var body: some View {
        NavigationLink(destination: RecordDetailView(record: record)) {
            HStack(spacing: 12) {
                // 类别图标
                categoryIcon(for: record.category)

                // 信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.activityName)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(formatTime(record.startTime))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let endTime = record.endTime {
                            Text("→")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(formatTime(endTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let mood = record.mood {
                            Image(systemName: mood.iconName)
                                .font(.caption2)
                        }

                        if record.note != nil {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                // 时长
                Text(formatDuration(record.totalDuration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemBackground))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func categoryIcon(for categoryName: String?) -> some View {
        if let category = categoryName,
           let activityCategory = ActivityCategory.from(string: category) {
            // 预设分类
            ZStack {
                Circle()
                    .fill(activityCategory.swiftUIColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: activityCategory.icon)
                    .foregroundColor(activityCategory.swiftUIColor)
                    .font(.caption)
            }
        } else if let category = categoryName,
                  let customCategory = customCategories.first(where: { $0.name == category }) {
            // 自定义分类
            ZStack {
                Circle()
                    .fill(customCategory.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: customCategory.icon)
                    .foregroundColor(customCategory.color)
                    .font(.caption)
            }
        } else {
            // 未分类
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "star.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
}
