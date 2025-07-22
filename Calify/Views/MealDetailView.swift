/**
 
 struct NutrientTotals { //struct, better for type safety.
     let totalCalories: Int
     let totalProtein: Int
     let totalCarbs: Int
     let totalFat: Int
 }
 
 
 */



import SwiftUI

struct MealDetailView: View {
    @State private var profile: Profiles? = nil

    let meal: MealEstimate
    
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 20) {
                // Calorie and Macros Summary Card
                
                
                DailySummaryCard(summary: NutrientTotals(totalCalories: meal.calories, totalProtein: meal.protein, totalCarbs: meal.carbs, totalFat: meal.fat))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .background(Color(.secondarySystemBackground)
                    .cornerRadius(12))
                
                // Accuracy Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Accuracy Details")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HStack(alignment: .top, spacing: 24) {
                        ScoreGaugeView(
                            score: meal.accuracyScore,
                            title: "accuracy",
                            description: "How certain we are about these values"
                        )
                        
                        Spacer()
                        
                        if let mealId = meal.id {
                            FeedbackCard(mealId: mealId, accuracyFeedback: meal.accuracyFeedback)
                        }
                    }
                    
                    if meal.accuracyScore < 70 {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.blue)
                            Text("These values are estimates based on available data")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Detailed Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Meal Details")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text(meal.description)
                        .font(.body)
                        .lineSpacing(5)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Time Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Information")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text(formattedDate(from: meal.created_at ?? Date()))
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                        Text(formattedTime(from: meal.created_at ?? Date()))
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    
    private func formattedDate(from timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: timestamp)
    }
    
    private func formattedTime(from timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

