//
//  MealCacheManager.swift
//  Calify
//
//  Created by justin lorenzo on 7/17/25.
//

import Foundation
import Combine

//class MealCacheManager: ObservableObject {
//    // The cached meals, published so views can react to changes
//    @Published private(set) var cachedMeals: [MealEstimate] = []
//
//    // Optional: Keep track of which day the cache belongs to (for daily reset)
//    private var cacheDate: Date = Calendar.current.startOfDay(for: Date())
//
//    // MARK: - Initialization
//
//    init() {
//        // Optionally load cache from disk here if you want persistence
//        clearCacheIfNewDay()
//    }
//
//    // MARK: - Cache Management
//
//    func addMeal(_ meal: MealEstimate) {
//        cachedMeals.append(meal)
//    }
//
//    func removeMeal(_ meal: MealEstimate) {
//        cachedMeals.removeAll { $0.id == meal.id }
//    }
//
//    func updateMeal(_ meal: MealEstimate) {
//        if let index = cachedMeals.firstIndex(where: { $0.id == meal.id }) {
//            cachedMeals[index] = meal
//        }
//    }
//
//    func clearCacheIfNewDay() {
//        let today = Calendar.current.startOfDay(for: Date())
//        if today > cacheDate {
//            cachedMeals.removeAll()
//            cacheDate = today
//        }
//    }
//
//    // Optional: Method to replace entire cache (e.g. after fetching from backend)
//    func setCache(_ meals: [MealEstimate]) {
//        cachedMeals = meals
//        cacheDate = Calendar.current.startOfDay(for: Date())
//    }
//}
final class MealCacheManager {
    static let shared = MealCacheManager()
    
    private init() {}
    
    private var mealCache: [MealEstimate] = []

    func addMeal(_ meal: MealEstimate) {
        mealCache.insert(meal, at: 0)
    }

    func getRecentMeals() -> [MealEstimate] {
        return mealCache
    }
    
    func setMeals(_ meals: [MealEstimate]) {
        mealCache = meals
    }
    
    func removeMeal(withId id: Int) {
        mealCache.removeAll { $0.id == id }
    }
    
    func updateFeedback(for mealId: Int, with feedback: String) {
        guard let index = mealCache.firstIndex(where: { $0.id == mealId }) else { return }
        var updatedMeal = mealCache[index]
        updatedMeal.accuracyFeedback = feedback
        mealCache[index] = updatedMeal
    }

    func clearCache() {
        mealCache.removeAll()
    }
}
