//
//  MacroNutrient.swift
//  mine
//
//  Created by justin lorenzo on 7/1/25.
//
import SwiftUI

struct MacroNutrient: View {
    var value: Int
    var label: String
    var color: Color
    
    var body: some View {
           VStack(spacing: 2) {
               Text("\(value)g")
                   .font(.system(size: 16, weight: .semibold))
                   .foregroundColor(color)
                   .lineLimit(1)
                   .minimumScaleFactor(0.75)

               Text(label)
                   .font(.caption2)
                   .foregroundColor(.secondary)
                   .lineLimit(1)
                   .minimumScaleFactor(0.75)
           }
           .frame(maxWidth: .infinity) // Makes all macros equal width
       }
}
