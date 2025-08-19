//
//  MacroOverview.swift
//  Calify
//
//  Created by justin lorenzo on 8/3/25.
//
import SwiftUI

struct MacroOverview: View {

    let profile: Profiles
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @Binding var selectedDate: Date
    var onTap: () -> Void

    var body: some View {
        let totals = nutritionManager.totals(for: selectedDate) ?? .init(totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0)
        let calGoal = profile.cal_goal ?? 2000
        let macros = [
            MacroData(label: "Protein", current: totals.totalProtein, emoji: "🍗", goal: profile.protein_goal ?? 50, color: .red),
            MacroData(label: "Carbs", current: totals.totalCarbs, emoji: "🍞", goal: profile.carb_goal ?? 200, color: .blue),
            MacroData(label: "Fat", current: totals.totalFat, emoji: "🧀", goal: profile.fat_goal ?? 70, color: .orange)
        ]
    
        HStack(alignment: .top, spacing: 16) {
            // Left: Calories Card
            ZStack(alignment: .topLeading) {
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .shadow(color: Color.primary.opacity(0.1), radius: 4)
                    .overlay(
                        CalProgress(calGoal: calGoal, currCal: totals.totalCalories)
                            .padding(.bottom, 20),
                        alignment: .bottom
                    )
                    .onTapGesture {
                        onTap()
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\( (calGoal - totals.totalCalories) <= 0 ? 0 : calGoal - totals.totalCalories )")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)

                    Text("calories remaining")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                .padding(.leading, 20)
            }
            .frame(width: UIScreen.main.bounds.width * 0.48, height: 350)

            // Right: Macro Cards
            VStack(spacing: 12) {
                ForEach(macros, id: \.self) { macro in
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .shadow(color: Color.primary.opacity(0.1), radius: 4)
                        
                        MacroProgress(
                            label: macro.label,
                            current: macro.current,
                            emoji: macro.emoji,
                            goal: macro.goal,
                            color: macro.color,
                            unit: "g"
                        )
                        .onTapGesture {
                            onTap()
                        }
                    }
                    .frame(height: (350 - 2 * 12) / 3)
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.42)
        }
    }
}


struct MacroData: Hashable {
    let label: String
    let current: Int
    let emoji: String
    let goal: Int
    let color: Color
}
