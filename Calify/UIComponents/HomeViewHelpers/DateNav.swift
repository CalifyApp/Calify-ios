//
//  Untitled.swift
//  Calify
//
//  Created by justin lorenzo on 8/3/25.
//

import SwiftUI

struct DateNav: View {
    @Binding var selectedDate: Date
    @State private var currentWeekStart: Date = Date().startOfWeek()
    let nutritionManager: DailyNutritionManager

    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let calendar = Calendar.current

    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .shadow(color: Color.primary.opacity(0.05), radius: 3, x: 0, y: 2) 
                    .frame(height: 75)

                VStack(spacing: 8) {
                    // Day initial letters
                    HStack {
                        ForEach(daysOfWeek.indices, id: \.self) { day in
                            Text(daysOfWeek[day])
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Date buttons
                    HStack {
                        ForEach(0..<7, id: \.self) { offset in
                            let date = calendar.date(byAdding: .day, value: offset, to: currentWeekStart)!
                            let day = calendar.component(.day, from: date)
                            let isToday = calendar.isDateInToday(date)
                            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

                            Button(action: {
                                selectedDate = date
                                nutritionManager.refresh(for: selectedDate)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? Color.accentColor : .clear)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.accentColor.opacity(isToday ? 0.5 : 0), lineWidth: 2)
                                        )
                                        .frame(width: 32, height: 32)

                                    Text("\(day)")
                                        .foregroundColor(isSelected ? .white : .primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)

                // Chevron buttons
                HStack {
                    Button(action: { goToPreviousWeek() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .padding()
                    }

                    Spacer()

                    Button(action: { goToNextWeek() }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.primary)
                            .padding()
                    }
                    .disabled(isAtCurrentWeek)
                }
                .padding(.horizontal, -10)
            }
            .frame(height: 75)
            .padding(.horizontal)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            // Swiped left → go to next week (if allowed)
                            goToNextWeek()
                        } else if value.translation.width > 50 {
                            // Swiped right → go to previous week
                            goToPreviousWeek()
                        }
                    }
            )
        }
    }

    private var isAtCurrentWeek: Bool {
        calendar.isDate(currentWeekStart, inSameDayAs: Date().startOfWeek())
    }

    private func goToNextWeek() {
        guard !isAtCurrentWeek else { return }
        withAnimation {
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)!
        }
    }

    private func goToPreviousWeek() {
        withAnimation {
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}

extension Date {
    func startOfWeek(using calendar: Calendar = Calendar.current) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }
}
