//
//  MealCacheManager.swift
//  Calify
//
//  Created by justin lorenzo on 7/17/25.
//

import Foundation
import Combine
//
////class MealCacheManager: ObservableObject {
////    // The cached meals, published so views can react to changes
////    @Published private(set) var cachedMeals: [MealEstimate] = []
////
////    // Optional: Keep track of which day the cache belongs to (for daily reset)
////    private var cacheDate: Date = Calendar.current.startOfDay(for: Date())
////
////    // MARK: - Initialization
////
////    init() {
////        // Optionally load cache from disk here if you want persistence
////        clearCacheIfNewDay()
////    }
////
////    // MARK: - Cache Management
////
////    func addMeal(_ meal: MealEstimate) {
////        cachedMeals.append(meal)
////    }
////
////    func removeMeal(_ meal: MealEstimate) {
////        cachedMeals.removeAll { $0.id == meal.id }
////    }
////
////    func updateMeal(_ meal: MealEstimate) {
////        if let index = cachedMeals.firstIndex(where: { $0.id == meal.id }) {
////            cachedMeals[index] = meal
////        }
////    }
////
////    func clearCacheIfNewDay() {
////        let today = Calendar.current.startOfDay(for: Date())
////        if today > cacheDate {
////            cachedMeals.removeAll()
////            cacheDate = today
////        }
////    }
////
////    // Optional: Method to replace entire cache (e.g. after fetching from backend)
////    func setCache(_ meals: [MealEstimate]) {
////        cachedMeals = meals
////        cacheDate = Calendar.current.startOfDay(for: Date())
////    }
////}
//final class MealCacheManager {
//    static let shared = MealCacheManager()
//
//    private init() {
//        loadCache()
//    }
//
//    private var mealCache: [MealEstimate] = []
//
//    private let fileName = "meal_cache.json"
//
//    func addMeal(_ meal: MealEstimate) {
//        mealCache.insert(meal, at: 0)
//        saveCache()
//    }
//
//    func getRecentMeals() -> [MealEstimate] {
//        return mealCache
//    }
//
//    func setMeals(_ meals: [MealEstimate]) {
//        mealCache = meals
//        saveCache()
//    }
//
//    func removeMeal(withId id: Int) {
//        mealCache.removeAll { $0.id == id }
//        saveCache()
//    }
//
//    func updateFeedback(for mealId: Int, with feedback: String) {
//        guard let index = mealCache.firstIndex(where: { $0.id == mealId }) else { return }
//        var updatedMeal = mealCache[index]
//        updatedMeal.accuracyFeedback = feedback
//        mealCache[index] = updatedMeal
//        saveCache()
//    }
//
//    func clearCache() {
//        mealCache.removeAll()
//        deleteCacheFile()
//    }
//
//    private func saveCache() {
//        let url = getFileURL()
//        do {
//            let data = try JSONEncoder().encode(mealCache)
//            try data.write(to: url, options: .atomic)
//        } catch {
//            print("❌ Failed to save meal cache:", error)
//        }
//    }
//
//    private func loadCache() {
//        let url = getFileURL()
//        do {
//            let data = try Data(contentsOf: url)
//            mealCache = try JSONDecoder().decode([MealEstimate].self, from: data)
//        } catch {
//            print("⚠️ No previous cache found or failed to load:", error)
//            mealCache = []
//        }
//    }
//
//    private func deleteCacheFile() {
//        let url = getFileURL()
//        try? FileManager.default.removeItem(at: url)
//    }
//
//    private func getFileURL() -> URL {
//        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        return directory.appendingPathComponent(fileName)
//    }
//}

final class MealCacheManager {
    static let shared = MealCacheManager()

    private init() {
        loadCache()
    }

    private var mealCache: [String: [MealEstimate]] = [:] // Key = "YYYY-MM-DD"

    private let fileName = "meal_cache.json"

    func addMeal(_ meal: MealEstimate) {
        guard let createdAt = meal.created_at else {
            print("⚠️ Skipping meal — created_at is nil")
            return
        }
        
        let dateKey = dateFormatter.string(from: createdAt)
        
        if mealCache[dateKey] != nil {
            mealCache[dateKey]?.insert(meal, at: 0)
        } else {
            mealCache[dateKey] = [meal]
        }
        
        saveCache()
    }
    
    func addMeal(_ meal: MealEstimate, for date: Date) {
        let dateKey = dateFormatter.string(from: date)
        if mealCache[dateKey] != nil {
            mealCache[dateKey]?.insert(meal, at: 0)
        } else {
            mealCache[dateKey] = [meal]
        }
        saveCache()
    }


    func getMeals(for date: Date) -> [MealEstimate] {
        let dateKey = dateFormatter.string(from: date)
        return mealCache[dateKey] ?? []
    }

    func setMeals(_ meals: [MealEstimate], for date: Date) {
        let dateKey = dateFormatter.string(from: date)
        mealCache[dateKey] = meals
        saveCache()
    }

    func removeMeal(withId id: Int, on date: Date) {
        let dateKey = dateFormatter.string(from: date)
        guard var meals = mealCache[dateKey] else { return }
        meals.removeAll { $0.id == id }
        mealCache[dateKey] = meals
        saveCache()
    }

    func updateFeedback(for mealId: Int, with feedback: String, on date: Date) {
        let dateKey = dateFormatter.string(from: date)
        guard var meals = mealCache[dateKey] else { return }
        if let index = meals.firstIndex(where: { $0.id == mealId }) {
            var updatedMeal = meals[index]
            updatedMeal.accuracyFeedback = feedback
            meals[index] = updatedMeal
            mealCache[dateKey] = meals
            saveCache()
        }
    }

    func clearCache() {
        mealCache.removeAll()
        deleteCacheFile()
    }

    private func saveCache() {
        let url = getFileURL()
        do {
            let data = try JSONEncoder().encode(mealCache)
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ Failed to save meal cache:", error)
        }
    }

    private func loadCache() {
        let url = getFileURL()
        do {
            let data = try Data(contentsOf: url)
            mealCache = try JSONDecoder().decode([String: [MealEstimate]].self, from: data)
        } catch {
            print("⚠️ No previous cache found or failed to load:", error)
            mealCache = [:]
        }
    }

    private func deleteCacheFile() {
        let url = getFileURL()
        try? FileManager.default.removeItem(at: url)
    }

    private func getFileURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(fileName)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}
