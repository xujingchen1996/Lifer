//
//  StatisticsView.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \TimerRecord.startTime) private var records: [TimerRecord]
    @State private var timeRange: TimeRange = .week

    // 缓存计算结果 (性能优化)
    @State private var cachedTotalDuration: TimeInterval = 0
    @State private var cachedActivityData: [ActivityData] = []
    @State private var cachedTrendData: [TrendData] = []
    
    enum TimeRange {
        case day, week, month, year
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 时间范围选择器
                    Picker("时间范围", selection: $timeRange) {
                        Text("今日").tag(TimeRange.day)
                        Text("本周").tag(TimeRange.week)
                        Text("本月").tag(TimeRange.month)
                        Text("今年").tag(TimeRange.year)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: timeRange) { _, _ in
                        updateCache()  // 时间范围变化时重新计算缓存
                    }
                    
                    // 总计时间卡片
                    VStack(alignment: .leading) {
                        Text("总计时间")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(cachedTotalDuration))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 活动分布图表
                    VStack(alignment: .leading) {
                        Text("活动分布")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        if cachedActivityData.isEmpty {
                            Text("暂无数据")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            Chart(cachedActivityData) { item in
                                SectorMark(
                                    angle: .value("时长", item.duration),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("活动", item.name))
                                .annotation(position: .overlay) {
                                    Text(formatPercentage(item.duration, of: cachedTotalDuration))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 240)
                            .chartLegend(position: .bottom, alignment: .center)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // 趋势图表
                    VStack(alignment: .leading) {
                        Text("时间趋势")
                            .font(.headline)
                            .padding(.bottom, 8)

                        if cachedTrendData.isEmpty {
                            Text("暂无数据")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            Chart(cachedTrendData) { item in
                                BarMark(
                                    x: .value("日期", item.date, unit: timeRangeUnit),
                                    y: .value("时长", item.duration / 3600) // 转换为小时
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks(position: .leading) { _ in
                                    AxisValueLabel(format: Decimal.FormatStyle.number.precision(.fractionLength(1)))
                                    AxisGridLine()
                                }
                            }
                            .chartYAxisLabel("小时")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("统计")
        }
        .onAppear {
            updateCache()  // 初始加载时计算缓存
        }
    }

    // MARK: - 缓存管理

    private func updateCache() {
        cachedTotalDuration = totalDuration
        cachedActivityData = activityData
        cachedTrendData = trendData
    }
    
    // 根据选择的时间范围筛选记录
    private var filteredRecords: [TimerRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return records.filter { record in
            guard let endTime = record.endTime else { return false }
            
            switch timeRange {
            case .day:
                return calendar.isDateInToday(endTime)
            case .week:
                let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                return endTime >= startOfWeek
            case .month:
                let components = calendar.dateComponents([.year, .month], from: now)
                let startOfMonth = calendar.date(from: components)!
                return endTime >= startOfMonth
            case .year:
                let components = calendar.dateComponents([.year], from: now)
                let startOfYear = calendar.date(from: components)!
                return endTime >= startOfYear
            }
        }
    }
    
    // 计算总时长
    private var totalDuration: TimeInterval {
        filteredRecords.reduce(0) { $0 + $1.totalDuration }
    }
    
    // 活动分布数据
    private var activityData: [ActivityData] {
        let grouped = Dictionary(grouping: filteredRecords) { $0.activityName }
        
        return grouped.map { name, records in
            let duration = records.reduce(0) { $0 + $1.totalDuration }
            return ActivityData(name: name, duration: duration)
        }
        .sorted { $0.duration > $1.duration }
    }
    
    // 时间趋势数据
    private var trendData: [TrendData] {
        let calendar = Calendar.current
        var result: [TrendData] = []
        
        // 根据选择的时间范围创建日期区间
        switch timeRange {
        case .day:
            // 按小时统计
            for hour in 0..<24 {
                let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
                let duration = durationForHour(hour)
                result.append(TrendData(date: date, duration: duration))
            }
        case .week:
            // 按天统计
            let today = calendar.startOfDay(for: Date())
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                    let duration = durationForDay(date)
                    result.append(TrendData(date: date, duration: duration))
                }
            }
            result.reverse()
        case .month:
            // 按天统计
            let today = calendar.startOfDay(for: Date())
            let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
            for day in 0..<daysInMonth {
                if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                    if calendar.isDate(date, equalTo: today, toGranularity: .month) {
                        let duration = durationForDay(date)
                        result.append(TrendData(date: date, duration: duration))
                    }
                }
            }
            result.reverse()
        case .year:
            // 按月统计
            let components = calendar.dateComponents([.year], from: Date())
            for month in 1...12 {
                var dateComponents = components
                dateComponents.month = month
                dateComponents.day = 1
                if let date = calendar.date(from: dateComponents) {
                    let duration = durationForMonth(month)
                    result.append(TrendData(date: date, duration: duration))
                }
            }
        }
        
        return result
    }
    
    // 获取特定小时的时长
    private func durationForHour(_ hour: Int) -> TimeInterval {
        let calendar = Calendar.current
        return filteredRecords.reduce(0) { total, record in
            if let endTime = record.endTime,
               calendar.component(.hour, from: endTime) == hour {
                return total + record.totalDuration
            }
            return total
        }
    }
    
    // 获取特定日期的时长
    private func durationForDay(_ date: Date) -> TimeInterval {
        let calendar = Calendar.current
        return filteredRecords.reduce(0) { total, record in
            if let endTime = record.endTime,
               calendar.isDate(endTime, inSameDayAs: date) {
                return total + record.totalDuration
            }
            return total
        }
    }
    
    // 获取特定月份的时长
    private func durationForMonth(_ month: Int) -> TimeInterval {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        
        return filteredRecords.reduce(0) { total, record in
            if let endTime = record.endTime,
               calendar.component(.year, from: endTime) == year,
               calendar.component(.month, from: endTime) == month {
                return total + record.totalDuration
            }
            return total
        }
    }
    
    // 图表时间单位
    private var timeRangeUnit: Calendar.Component {
        switch timeRange {
        case .day: return .hour
        case .week, .month: return .day
        case .year: return .month
        }
    }
    
    // 格式化持续时间显示
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // 格式化百分比显示
    private func formatPercentage(_ value: Double, of total: Double) -> String {
        if total == 0 { return "0%" }
        let percentage = (value / total) * 100
        return String(format: "%.0f%%", percentage)
    }
}

// 图表数据模型
struct ActivityData: Identifiable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
}

struct TrendData: Identifiable {
    let id = UUID()
    let date: Date
    let duration: TimeInterval
}
