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

        Task {
            do {
                let meals = try await SupabaseManager.shared.fetchMeals(for: date)
                todaysMeals = meals
                todaysTotal = aggregateMeals(meals: meals)
                isLoading = false
            } catch {
                errorMessage = "Error loading meals: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

