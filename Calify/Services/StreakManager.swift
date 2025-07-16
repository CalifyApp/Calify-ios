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
    
    func updateStreakOnMealAdded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: lastLoggedDateKey) as? Date

        if let last = lastDate {
            if Calendar.current.isDateInToday(last) {
                return
            }

            if Calendar.current.isDate(last, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: today)!) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }


       UserDefaults.standard.set(today, forKey: lastLoggedDateKey)
       UserDefaults.standard.set(currentStreak, forKey: streakKey)
        
        showBanner()
    }

    private func loadStreak() {
       currentStreak = UserDefaults.standard.integer(forKey: streakKey)
    }

    func showBanner() {
        showStreakBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showStreakBanner = false
        }
    }
//    func resetStreakForTesting() {
//        let defaults = UserDefaults.standard
//        currentStreak = 7
//        defaults.set(currentStreak, forKey: streakKey)
//
//        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
//            defaults.set(yesterday, forKey: lastLoggedDateKey)
//        }
//    }
}
