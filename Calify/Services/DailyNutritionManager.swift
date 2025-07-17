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
    @Published var todaysTotal: NutrientTotals? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func refresh(for date: Date = Date()) {
        isLoading = true
        errorMessage = nil
        
        if Calendar.current.isDateInToday(date) {
            let cachedMeals = MealCacheManager.shared.getRecentMeals()
            if !cachedMeals.isEmpty {
                // Use cache and skip fetch for now
                self.todaysMeals = cachedMeals
                self.todaysTotal = aggregateMeals(meals: cachedMeals)
                self.isLoading = false
                return
            }
        }

        Task {
            do {
                let meals = try await SupabaseManager.shared.fetchMeals(for: date)
                todaysMeals = meals
                todaysTotal = aggregateMeals(meals: meals)
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

