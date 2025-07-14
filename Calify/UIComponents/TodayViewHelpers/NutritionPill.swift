//
//  NutritionPill.swift
//  mine
//
//  Created by justin lorenzo on 7/1/25.
//
import SwiftUI

struct NutritionPill: View {
    var value: Int
    var unit: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
        .foregroundColor(color)
    }
}
