//
//  ProgressView.swift
//  Calify
//
//  Created by christopher on 8/8/25.
//

import SwiftUI
import Charts

struct GraphView: View {
    @State private var selectedTimeFrame: TimeFrame = .thisWeek
    @State private var dailyLimit: Double = 2500
    @State private var calorieData: [DailyCalories] = []
    
    //we need this to essentially, convert to chart format.
    func toDailyCalories(_ days: [SupabaseManager.DayTotal]) -> [DailyCalories] {
        days.map { d in
            DailyCalories(day: shortWeekday(d.day), calories: d.total, date: d.day)
        }
    }

    private func load() async {
        do {
            let days = try await SupabaseManager.shared.fetchMealsForWeek(for: selectedTimeFrame)
            await MainActor.run {
                calorieData = toDailyCalories(days)
            }
        } catch {
            print("fetch error:", error)
        }
    }
    
    var currentData: [DailyCalories] {
        calorieData //this variable setting format is essentially a computed property (recalculates every time its accessed )
    }
    
    var weekAverage: Int {
        guard !currentData.isEmpty else { return 0 }
        let total = currentData.reduce(0) { $0 + $1.calories }
        return total / currentData.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Progress")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Main Chart Card
            VStack(spacing: 20) {
                // Toggle Buttons
                HStack(spacing: 12) {
                    ToggleButton(
                        title: "Calories",
                        isSelected: true
                    ) {
                        // Already selected
                    }
                    
                    ToggleButton(
                        title: "Protein",
                        isSelected: false
                    ) {
                        // Future feature
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Chart
                VStack(alignment: .leading, spacing: 16) {
                    Chart(currentData, id: \.day) { item in
                        BarMark(
                            x: .value("day", item.day),
                            y: .value("total", item.calories)
                        )
                        .foregroundStyle(Color.blue)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...3000)
                    .chartYAxis {
                    
                        AxisMarks(preset: .automatic, position: .leading, values: [0, 500, 1000, 1500, 2000, 2500, 3000]) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.gray.opacity(0.3))
                            AxisValueLabel() {
                                if let intValue = value.as(Int.self) {
                                    Text("\(intValue)")
                                        .font(.caption)
                                        .foregroundStyle(Color.gray)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .overlay(
                        // Daily limit line
                        Rectangle()
                            .fill(Color.green)
                            .frame(height: 2)
                            .padding(.leading, 37) // Cuts 40 points from left side
                            .offset(y: chartYOffset(for: dailyLimit))
                            .opacity(0.8),
                        alignment: .bottom
                    )
                    .overlay(
                        // Daily limit label
                        HStack {
                            Spacer()
                            Text("Daily Limit")
                                .font(.caption)
                                .foregroundStyle(Color.green)
                                .fontWeight(.medium)
                        }
                        .offset(y: chartYOffset(for: dailyLimit) - 10),
                        alignment: .bottom
                    )
                }
                .padding(.horizontal, 20)
                
                // Week Average
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Week Average")
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                        Spacer()
                    }
                    
                    Text("\(weekAverage)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                
                // Time Frame Selector
                HStack(spacing: 8) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                        TimeFrameButton(
                            title: timeFrame.displayName,
                            isSelected: selectedTimeFrame == timeFrame
                        ) {
                            selectedTimeFrame = timeFrame
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await load()
                        }
                    } label: {
                        Text("Reload Data")
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
        }
        .gradientBackground()
        .task {
            await load() // Load initial data when view appears
        }
        .onChange(of: selectedTimeFrame) { _, newTimeFrame in
            Task {
                await load() // Reload data when time frame changes
            }
        }
    }
    
    // Helper function to calculate Y offset for the daily limit line
    private func chartYOffset(for value: Double) -> CGFloat {
        let chartHeight: CGFloat = 200
        let maxValue: Double = 3000
        let percentage = value / maxValue
        return chartHeight * (1 - percentage) - chartHeight
    }
    
    //helper function to converta  date into 3 letter weekday (Mon, Tue)
    func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE") // short day format
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

}

// MARK: - Supporting Views
struct ToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.white : Color.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.clear)
                        .stroke(Color.blue, lineWidth: 1.5)
                )
        }
    }
}

struct TimeFrameButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.white : Color.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
    }
}

// MARK: - Data Models
struct DailyCalories {
    let day: String
    let calories: Int
    let date: Date
}

enum TimeFrame: CaseIterable {
    case thisWeek
    case lastWeek
    case twoWeeksAgo
    case threeWeeksAgo
    
    var displayName: String {
        switch self {
        case .thisWeek: return "This week"
        case .lastWeek: return "Last week"
        case .twoWeeksAgo: return "2 wks ago"
        case .threeWeeksAgo: return "3 wks ago"
        }
    }
    
    var key: String {
        switch self {
        case .thisWeek: return "thisWeek"
        case .lastWeek: return "lastWeek"
        case .twoWeeksAgo: return "twoWeeksAgo"
        case .threeWeeksAgo: return "threeWeeksAgo"
        }
    }
}
