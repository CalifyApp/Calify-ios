import SwiftUI

struct MealResultView: View {
    let result: MealEstimate
    
    @State private var showConfirmation = false
    
    
    var body: some View {
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
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How to improve accuracy:")
                            .font(.headline)

                        ForEach(tips, id: \.self) { tip in
                            Text("• \(tip)")
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true) // 🔥 forces wrapping
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(10)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.9) // 🔥 clamps the whole thing
                }
            }

            // Optional tip for improving results
            if result.accuracyScore < 70 {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.blue)
                    Text("Adding more meal details improves accuracy!")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer().frame(height: 60) // or however much space you want
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
                    withAnimation {
                        showConfirmation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showConfirmation = false
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
            .scaleEffect(1.2)
        }
        .padding()
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



//concurrency.

    //we perform this by. letting the calorie estimate build, but dont WAIT on that to complete, concurrently, wait on the accruacy prompt to build, Then once thats done,
