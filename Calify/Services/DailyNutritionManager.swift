//
//  DailyNutritionManager.swift
//  mine
//
//  Created by justin lorenzo on 7/1/25.
//

import Foundation

@MainActor
class DailyNutritionManager: ObservableObject {
    
    @Published var todaysMeals: [MealEstimate] = []
    @Published var dailyTotals: [String: NutrientTotals] = [:]
//    @Published var todaysTotal: NutrientTotals? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
//    init(){
//        refresh()
//    }
    
    func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func totals(for date: Date) -> NutrientTotals? {
        let key = dateKey(for: date)
        return dailyTotals[key]
    }
    

    func refresh(for date: Date = Date()) {
        isLoading = true
        errorMessage = nil
        
        if Calendar.current.isDateInToday(date) {
            let cachedMeals = MealCacheManager.shared.getRecentMeals()
            if !cachedMeals.isEmpty {
                // Use cache and skip fetch for now
                self.todaysMeals = cachedMeals
                let key = dateKey(for: date)
                dailyTotals[key] = aggregateMeals(meals: cachedMeals)
                self.isLoading = false
                return
            }
        }

        Task {
            do {
                let meals = try await SupabaseManager.shared.fetchMeals(for: date)
                todaysMeals = meals
                let key = dateKey(for: date)
                dailyTotals[key] = aggregateMeals(meals: meals)
                isLoading = false
                if Calendar.current.isDateInToday(date) {
                    MealCacheManager.shared.setMeals(meals)
                }
            } catch {
                errorMessage = "Error loading meals: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

