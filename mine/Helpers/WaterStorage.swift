
//
//  WaterStorage.swift
//  Calify
//
//  Created by justin lorenzo on 6/20/25.
//
import SwiftUI

struct WaterTrackerStorage {
    private static let intakeKey = "currentIntake"
    private static let dateKey = "lastUpdatedDate"
    private static let goalKey = "dailyGoal"

    static func save(intake: Int) {
        UserDefaults.standard.set(intake, forKey: intakeKey)
        UserDefaults.standard.set(Date(), forKey: dateKey)
    }

    static func loadIntake() -> Int {
        let savedDate = UserDefaults.standard.object(forKey: dateKey) as? Date ?? Date.distantPast

        if !Calendar.current.isDateInToday(savedDate) {
            return 0
        }

        return UserDefaults.standard.integer(forKey: intakeKey)
    }
    
    static func saveGoal(_ goal: Int) {
        UserDefaults.standard.set(goal, forKey: goalKey)
    }

    static func loadGoal() -> Int {
        let value = UserDefaults.standard.integer(forKey: goalKey)
        return value > 0 ? value : 100
    }
}
