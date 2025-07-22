//
//  TimelineBar.swift
//  Calify
//
//  Created by justin lorenzo on 7/22/25.
//

import SwiftUI

struct TimelineBar: View {
    @ObservedObject var waterManager: WaterManager
//    @State var entries: [WaterEntry]
//    let entryTimes: [Date]
    
    let startHour = 0
    let endHour = 24
    
    @State private var showSheet = false

    var totalHours: Int {
        endHour - startHour
    }

    var body: some View {
        let todayEntries = waterManager.entries.filter {
                    Calendar.current.isDateInToday($0.timestamp)
                }
        GeometryReader { geometry in
            
            let availableWidth = geometry.size.width
            let numberOfLabels = 4
            let spacing = availableWidth / CGFloat(numberOfLabels)
            
            VStack(spacing: 6) {
                
                ZStack(alignment: .leading) {
                    // Background bar
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 2)
                    
                    ForEach(Array(stride(from: 0, through: 24, by: 6)), id: \.self) { hour in
                        let percent = CGFloat(hour - startHour) / CGFloat(totalHours)
                        let xPosition = percent * availableWidth

                        Capsule()
                            .fill(Color.gray)
                            .frame(width: 2, height: 16)
                            .offset(x: xPosition - 1)
                    }
                    
                    // Entry lines
                    ForEach(todayEntries, id: \.id) { entry in
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 2, height: 6)
                            .offset(x: xOffset(for: entry.timestamp, in: geometry.size.width) - 1)
                    }
                }
                
                HStack(spacing: 0) {
                    ForEach(Array(stride(from: 0, through: 24, by: 6)), id: \.self) { hour in
                        Text(timeLabel(for: hour))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(width: spacing, alignment: .center)
                            // position etc.
                    }
                }
                .frame(width: availableWidth)
                
                Button(action: {
                    showSheet = true
                }) {
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .padding(10) // Adds invisible tappable area around the icon
                        .padding(.bottom, 4)
                        .contentShape(Rectangle()) // Makes the whole padded area tappable
                }
                .sheet(isPresented: $showSheet) {
                    VStack(alignment: .leading) {
                        Text("Today's Entries")
                            .font(.headline)
                            .padding(.top)

                        List {
                            ForEach(todayEntries, id: \.id) { entry in
                                HStack {
                                    Text("\(entry.amount) oz")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(entry.timestamp, style: .time)
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deleteEntry)
                        }
                    }
                    .presentationDetents([.medium, .large])
                }

            }
        }
        .frame(height: 40)
    }
    
    private func deleteEntry(at offsets: IndexSet) {
        let todayEntries = waterManager.entries.enumerated().filter {
            Calendar.current.isDateInToday($0.element.timestamp)
        }
        let indicesToDelete = offsets.compactMap { offset in
            todayEntries[offset].offset
        }
        for index in indicesToDelete.sorted(by: >) {
            waterManager.entries.remove(at: index)
        }
    }


    private func xOffset(for date: Date, in totalWidth: CGFloat) -> CGFloat {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        let decimalHour = Double(hour) + Double(minute) / 60.0
        let percent = (decimalHour - Double(startHour)) / Double(totalHours)
        return CGFloat(percent) * totalWidth
    }

//    private func hourLabel(for hour: Int) -> String {
//        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
//        let formatter = DateFormatter()
//        formatter.dateFormat = "ha"
//        formatter.amSymbol = "AM"
//        formatter.pmSymbol = "PM"
//        return formatter.string(from: date)
//    }
    
    func timeLabel(for hour: Int) -> String {
        let normalizedHour = hour % 24
        switch normalizedHour {
        case 0:
            return "12am"
        case 6:
            return "6am"
        case 12:
            return "12pm"
        case 18:
            return "6pm"
        default:
            return ""
        }
    }
}


