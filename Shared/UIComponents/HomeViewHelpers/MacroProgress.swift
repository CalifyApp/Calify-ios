//
//  MacroProgress.swift
//  Calify
//
//  Created by justin lorenzo on 8/4/25.
//
import SwiftUI

struct MacroProgress: View {
    let label: String
    let current: Int
    let emoji: String
    let goal: Int
    let color: Color
    let unit: String
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }
    
    private var progressText: String {
        "\(current)/\(goal)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)
                
                VStack(spacing: 0) {
                    Text("\(emoji)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(color)
//                    Text(unit)
//                        .font(.system(size: 10))
//                        .foregroundColor(.secondary)
                }
            }
            
            // Right Side Texts
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Goal: \(goal) \(unit)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("\( (goal - current) <= 0 ? 0 : (goal - current) )\(unit) left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(progress >= 1.0 ? .green : color)
                    .opacity(0.85)
            }
        }
        .padding(.vertical, 8)
    }
}

