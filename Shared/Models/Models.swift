import Foundation
struct MealEstimate: Codable, Hashable { //codable protocol enables ability to decode json received from openai.
    let id: Int? //optional, id of meal.
    let user_id: UUID? // optional bc, dont need it for openai
    let protein: Int
    let carbs: Int
    let fat: Int
    let calories: Int
    let description: String
    let accuracyScore: Int
    var accuracyFeedback: String?
    let created_at: Date?
    let tips:[String]
}
struct Profiles: Codable {
    let id: UUID?
    let created_at: Date?
    let name: String?
    let cal_goal: Int?
    let protein_goal: Int?
    let fat_goal: Int?
    let carb_goal: Int?
}
