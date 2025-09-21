//
//  HistoryView.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimerRecord.startTime, order: .reverse) private var records: [TimerRecord]
    @State private var selectedDate: Date = Date()
    
    private var calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            VStack {
                // 日历视图
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                // 当日记录列表
                List {
                    ForEach(filteredRecords) { record in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(record.activityName)
                                    .font(.headline)
                                
                                Text(formatDate(record.startTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(formatDuration(record.totalDuration))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteRecords)
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("历史记录")
        }
    }
    
    // 筛选当前选中日期的记录
    private var filteredRecords: [TimerRecord] {
        records.filter { record in
            calendar.isDate(record.startTime, inSameDayAs: selectedDate)
        }
    }
    
    // 格式化日期显示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
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
    
    // 删除记录
    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredRecords[index])
        }
        try? modelContext.save()
    }
}
