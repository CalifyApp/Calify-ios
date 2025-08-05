//
//   CalProgress.swift
//  Calify
//
//  Created by justin lorenzo on 8/4/25.
//

import SwiftUI

struct CalProgress: View {
    let calGoal: Int
    let currCal: Int
    
    var body: some View {
        ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 14)
                    .frame(width: 120, height: 120)

                // Progress Circle
                Circle()
                    .trim(from: 0, to: min(Double(currCal) / Double(calGoal), 1.0))
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                    .animation(.easeInOut(duration: 0.8), value: currCal)

                // Lightning Bolt
                Image(systemName: "bolt")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }
            .padding(.top, 12)
    }
}
