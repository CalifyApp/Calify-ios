import SwiftUI

struct MealResultView: View {
    let result: MealEstimate
    
    @State private var showConfirmation = false
    @State private var isExpanded = false
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    
    
    var body: some View {
        ZStack(alignment: .bottom){
            ScrollView {
                VStack(spacing: 24) {
                    Text("\(result.calories) Calories")
                        .font(.system(size: 36, weight: .bold))
                    
                    HStack(spacing: 8) {
                        NutritionPill(value: result.protein, unit: "Protein", color: Color.blue)
                        NutritionPill(value: result.carbs, unit: "Carbs", color: Color.green)
                        NutritionPill(value: result.fat, unit: "Fat", color: Color.orange)
                        
                    }
                    .font(.title3)
                    .scaleEffect(1.1)
                    
                    // Add accuracy gauge
                    HStack(spacing: 16) {
                        ScoreGaugeView(
                            score: result.accuracyScore,
                            title: "accuracy",
                            description: "How certain we are about these values"
                        )
                    }
                    .padding(.top, 10)
                    
                    let tips = formattedTips(from: OpenAIManager.shared.getRawAccuracyTips())

                    if !tips.isEmpty {
                        DisclosureGroup(
                            isExpanded: $isExpanded.animation(.easeInOut),
                            content: {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(tips, id: \.self) { tip in
                                        Text("\(tip)")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            },
                            label: {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("How to improve your accuracy")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                            }
                        )
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground)) // adapts to light/dark mode
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )

                    }
                    
                }
                .padding()
            }
            VStack {
                        if showConfirmation {
                            Text("Meal saved!")
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }

                        Button("Save Meal") {
                            Task {
                                await SupabaseManager.shared.insertMeal(
                                    description: result.description,
                                    calories: result.calories,
                                    protein: result.protein,
                                    carbs: result.carbs,
                                    fat: result.fat,
                                    accuracyScore: result.accuracyScore
                                )
                                await MainActor.run {
                                    withAnimation {
                                        showConfirmation = true
                                    }
                                    nutritionManager.refresh() // ✅ Refresh after save completes
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showConfirmation = false
                                    }

                                }
                                
                            }
                            nutritionManager.refresh() 
                        }
                        .buttonStyle(.borderedProminent)
                        .scaleEffect(1.2)
                    }
                    .padding()
//                    .background(.thinMaterial)
        }
        .navigationTitle("Meal Breakdown")
    }
    
    func formattedTips(from raw: String) -> [String] {
        guard let data = raw.data(using: .utf8),
              let tips = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return tips
    }
}


//#Preview {
//    NavigationView {
//
//    }
//}
//concurrency.

    //we perform this by. letting the calorie estimate build, but dont WAIT on that to complete, concurrently, wait on the accruacy prompt to build, Then once thats done,
