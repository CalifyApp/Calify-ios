//
//  MacroItem.swift
//  mine
//
//  Created by justin lorenzo on 7/1/25.
//
import SwiftUI

struct MacroItem: View {
    var value: Int
    var label: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)g")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}
