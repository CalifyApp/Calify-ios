//
//  PendingMeal.swift
//  Calify
//
//  Created by justin lorenzo on 8/19/25.
//
import SwiftUI

struct PendingMeal: Codable, Identifiable {
    let id: UUID
    let description: String
    let date: Date
}

struct PendingMealProcessor {
    
    static func processPendingMeals(nutritionManager: DailyNutritionManager)  {
        let pendingMeals = PendingMealStore.getAll()
        
        for pending in pendingMeals {
//            await MainActor.run {
//                nutritionManager.insertPlaceholderMeal(for: pending.date, tempID: pending.id)
//            }
            Task { @MainActor in
                nutritionManager.insertPlaceholderMeal(for: pending.date, tempID: pending.id)
            }
        }
        
        for meal in pendingMeals {
            Task {
                do {
                    // Call OpenAI
                    let jsonMealEstimatesResult = await SupabaseManager.shared.callOpenAI(meal: meal.description)
                    
                    switch jsonMealEstimatesResult {
                    case .success(let jsonString):
                        if let data = jsonString.data(using: .utf8) {
                            let decoded = try JSONDecoder().decode(MealEstimate.self, from: data)
                            
                            try await SupabaseManager.shared.insertMeal(
                                description: decoded.description,
                                calories: decoded.calories,
                                protein: decoded.protein,
                                carbs: decoded.carbs,
                                fat: decoded.fat,
                                accuracyScore: decoded.accuracyScore,
                                tips: decoded.tips,
                                created_at: meal.date
                            )
                            
                            // Remove from pending after success
                            PendingMealStore.remove(meal)
                            await nutritionManager.removeLoadingMeal(for: meal.date, id: meal.id)
                            DispatchQueue.main.async {
                                nutritionManager.refresh(for: meal.date)
                            }
                        }
                    case .failure(let error):
                        print("Failed to process pending meal: \(error)")
                    }
                } catch {
                    print("Error processing pending meal \(meal.id): \(error)")
                }
            }
        }
    }
}


class PendingMealStore {
    private static let key = "pendingMeals"

    static func getAll() -> [PendingMeal] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let meals = try? JSONDecoder().decode([PendingMeal].self, from: data) else {
            return []
        }
        return meals
    }

    static func add(_ meal: PendingMeal) {
        var current = getAll()
        current.append(meal)
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func remove(_ meal: PendingMeal) {
        var current = getAll()
        current.removeAll { $0.id == meal.id }
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
