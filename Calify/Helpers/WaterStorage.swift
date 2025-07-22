
//
//  WaterStorage.swift
//  Calify
//
//  Created by justin lorenzo on 6/20/25.
//
import SwiftUI

struct WaterEntry: Codable, Identifiable {
    let id: UUID
    let amount: Int      // in oz
    let timestamp: Date
}


class WaterManager: ObservableObject {
    @Published private var midnightTimer: Timer?
    @Published var goal: Int
    @Published var entries: [WaterEntry] = [] {
        didSet {
            saveEntries()
        }
    }
    
    private let storageKey = "WaterEntries"
    
    init() {
        self.goal = UserDefaults.standard.integer(forKey: "dailyGoal")
        loadEntries()
    }
    
    func add(amount: Int) {
        if (amount <= 0) { return }
        let entry = WaterEntry(id: UUID(), amount: amount, timestamp: Date())
        entries.append(entry)
    }
    
    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }
    
    func scheduleMidnightReset() {
        midnightTimer?.invalidate()
        
        let calendar = Calendar.current
        let now = Date()
        let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime)!
        let interval = nextMidnight.timeIntervalSince(now)
        
        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.entries.removeAll()
            self.scheduleMidnightReset()
        }
    }
    
    func saveGoal(_ newGoal: Int) {
        guard newGoal > 0 && newGoal <= 1000 else { return }
        goal = newGoal
        UserDefaults.standard.set(newGoal, forKey: "dailyGoal")
    }

    func loadGoal() -> Int {
        let value = UserDefaults.standard.integer(forKey: "dailyGoal")
        return value > 0 ? value : 100
    }

    var totalToday: Int {
        let calendar = Calendar.current
        return entries
            .filter { calendar.isDateInToday($0.timestamp) }
            .map { $0.amount }
            .reduce(0, +)
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
        let decoded = try? JSONDecoder().decode([WaterEntry].self, from: data) {
        let calendar = Calendar.current
            entries = decoded.filter { calendar.isDateInToday($0.timestamp) }
        }
    }
}

