//
//  StreakManager.swift
//  Calify
//
//  Created by justin lorenzo on 6/23/25.
//
import SwiftUI
//import Foundation

class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var showStreakBanner: Bool = false

    private let streakKey = "currentStreak"
    private let lastLoggedDateKey = "lastLoggedDate"

    init() {
        loadStreak()
    }
    func printStreak() {
        print(currentStreak)
    }
    func loadStreak() {
        let defaults = UserDefaults.standard
        currentStreak = defaults.integer(forKey: streakKey)
    }

    func updateStreakOnMealAdded() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = defaults.object(forKey: lastLoggedDateKey) as? Date

        if let last = lastDate {
            if Calendar.current.isDateInToday(last) {
                return
            } else if Calendar.current.isDate(last, inSameDayAs: today.addingTimeInterval(-86400)) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        defaults.set(today, forKey: lastLoggedDateKey)
        defaults.set(currentStreak, forKey: streakKey)

        showBanner()
    }

    func showBanner() {
        showStreakBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showStreakBanner = false
        }
    }
    
    func resetStreakForTesting() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: lastLoggedDateKey)
        currentStreak = 0
    }

    var streakEmojiString: String {
        let active = String(repeating: "🔥", count: min(currentStreak, 7))
        let remaining = String(repeating: "⚪️", count: max(0, 7 - currentStreak))
        return active + remaining
    }
}
