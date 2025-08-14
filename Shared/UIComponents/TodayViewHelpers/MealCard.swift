//
//  MealCard.swift
//  mine
//
//  Created by justin lorenzo on 7/1/25.
//
import SwiftUI

struct MealCard: View {
    @State private var showDeleteConfirmation = false
    var meal: MealEstimate
    var onDelete: () -> Void
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            // Header with meal description and delete button
            HStack {
                Text(meal.description)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                    .padding(8)
//                    .background(Circle().fill(Color.gray.opacity(0.2)))
            }
            
            // Nutrition section
            HStack(alignment: .center, spacing: 16) {
                // Calories display
                VStack(spacing: 0) {
                    Text("\(meal.calories)")
                        .font(.system(size: 24, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Divider()
                    .frame(height: 40)

                // Equal-width macros
                HStack(spacing: 12) {
                    MacroNutrient(value: meal.protein, label: "protein", color: .red)
                    MacroNutrient(value: meal.carbs, label: "carbs", color: .blue)
                    MacroNutrient(value: meal.fat, label: "fat", color: .orange)
                }

                // Limit the size of the accuracy gauge
                ScoreGaugeView(
                    score: meal.accuracyScore,
                    title: "accuracy"
                )
                .frame(maxWidth: 80) // limit how wide it can go
            }
            
        }
        .padding()
//        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
