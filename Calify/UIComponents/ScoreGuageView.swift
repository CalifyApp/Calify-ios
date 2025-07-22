//
//  ScoreGuageView.swift
//  mine
//
//  Created by christopher on 4/12/25.
//

// hi

import Foundation
import SwiftUI

struct ScoreGaugeView: View {
    let score: Int
    let title: String
    let description: String?

    init(score: Int, title: String, description: String? = nil) {
        self.score = score
        self.title = title
        self.description = description
    }

    private var tier: Int {
        switch score {
        case ..<40: return 1   // LOW
        case 40..<70: return 2 // MEDIUM
        default: return 3      // HIGH
        }
    }

    private var color: Color {
        switch tier {
        case 1: return .gray
        case 2: return .yellow
        default: return .green
        }
    }

    private var tierLabel: String {
        switch tier {
        case 1: return "Quick"
        case 2: return "Good"
        default: return "Detailed"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Circle display (centered like old gauge)
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { index in
                        Circle()
                            .fill(index <= tier ? color : Color.gray.opacity(0.2))
                            .frame(width: 18, height: 18)
                    }
                }
                .frame(width: 100, height: 50, alignment: .center)
            }

            Text(tierLabel.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(width: 100, height: 50) // similar footprint to old view
    }
}
