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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func totals(for date: Date) -> NutrientTotals? {
        let key = dateKey(for: date)
        return dailyTotals[key]
    }
    
    func getMeals(for date: Date) -> [MealEstimate] {
        return MealCacheManager.shared.getMeals(for: date)
    }

    func refresh(for date: Date = Date()) {
        isLoading = true
        errorMessage = nil

        let key = dateKey(for: date)
        let cachedMeals = MealCacheManager.shared.getMeals(for: date)

        if !cachedMeals.isEmpty {
            self.todaysMeals = cachedMeals
            self.dailyTotals[key] = aggregateMeals(meals: cachedMeals)
            self.isLoading = false
            return
        }

        Task {
            do {
                let meals = try await SupabaseManager.shared.fetchMeals(for: date)
                self.todaysMeals = meals
                self.dailyTotals[key] = aggregateMeals(meals: meals)
                self.isLoading = false
                MealCacheManager.shared.setMeals(meals, for: date)
            } catch {
                self.errorMessage = "Error loading meals: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
