//
//  DailySummaryCard.swift
//  mine
//
//  Created by justin lorenzo on 7/1/25.
//
import SwiftUI

struct DailySummaryCard: View {
    var summary: NutrientTotals
    
    var body: some View {
        VStack(spacing: 16) {
            // Calories
            VStack(spacing: 4) {
                Text("\(summary.totalCalories)")
                    .font(.system(size: 36, weight: .bold))
                Text("Calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Divider
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
                .padding(.horizontal)
            
            // Macros
            HStack(spacing: 24) {
                MacroItem(value: summary.totalProtein, label: "Protein", color: .blue)
                MacroItem(value: summary.totalCarbs, label: "Carbs", color: .green)
                MacroItem(value: summary.totalFat, label: "Fat", color: .orange)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}
