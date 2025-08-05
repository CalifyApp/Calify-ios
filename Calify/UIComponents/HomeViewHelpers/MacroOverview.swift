//
//  MacroOverview.swift
//  Calify
//
//  Created by justin lorenzo on 8/3/25.
//
import SwiftUI

import SwiftUI

struct MacroOverview: View {
    let profile: Profiles
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @Binding var selectedDate: Date
    
    
    private var totals: NutrientTotals {
        nutritionManager.totals(for: selectedDate) ?? .init(
            totalCalories: 0,
            totalProtein: 0,
            totalCarbs: 0,
            totalFat: 0
        )
    }
    
    private var calGoal: Int { profile.cal_goal ?? 2000 }

    private var macros: [MacroData] {
        [
            MacroData(label: "Protein", current: totals.totalProtein, goal: profile.protein_goal ?? 50, color: .red),
            MacroData(label: "Carbs", current: totals.totalCarbs, goal: profile.carb_goal ?? 200, color: .blue),
            MacroData(label: "Fat", current: totals.totalFat, goal: profile.fat_goal ?? 70, color: .orange)
        ]
    }

    var body: some View {
    
        HStack(alignment: .top, spacing: 16) {
            // Left: Calories Card
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(radius: 4)
                    .overlay(
                        CalProgress(calGoal: calGoal, currCal: totals.totalCalories)
                            .padding(.bottom, 20),
                        alignment: .bottom
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(calGoal - totals.totalCalories)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.black)

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
                            .fill(Color.white)
                            .shadow(radius: 4)
                        
                        MacroProgress(
                            label: macro.label,
                            current: macro.current,
                            goal: macro.goal,
                            color: macro.color,
                            unit: "g"
                        )
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
    let goal: Int
    let color: Color
}
