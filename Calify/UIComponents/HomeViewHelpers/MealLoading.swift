//
//  MealLoading.swift
//  Calify
//
//  Created by justin lorenzo on 8/12/25.
//

import SwiftUI

struct MealLoading: View {
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with loading bar for meal description
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 20)
                    .modifier(LoadingFillBar(maxWidth: 150, height: 20, animationDuration: 1.5))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                    .padding(6)
            }

            // Nutrition section with loading placeholders
            HStack(alignment: .center, spacing: 16) {
                // Calories loading placeholder
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 28)
                        .modifier(LoadingFillBar(maxWidth: 50, height: 28, animationDuration: 1.5))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 14)
                        .modifier(LoadingFillBar(maxWidth: 60, height: 14, animationDuration: 1.5))
                }

                Divider()
                    .frame(height: 40)

                // Macros loading placeholders
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .modifier(LoadingFillBar(maxWidth: 40, height: 40, animationDuration: 1.5))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .modifier(LoadingFillBar(maxWidth: 40, height: 40, animationDuration: 1.5))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .modifier(LoadingFillBar(maxWidth: 40, height: 40, animationDuration: 1.5))
                }

                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct LoadingFillBar: ViewModifier {
    @State private var fillWidth: CGFloat = 0
    let maxWidth: CGFloat
    let height: CGFloat
    let animationDuration: Double

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            content
            
            RoundedRectangle(cornerRadius: height / 2)
                .fill(Color.white.opacity(0.6))
                .frame(width: fillWidth, height: height)
                .animation(.linear(duration: animationDuration).repeatForever(autoreverses: false), value: fillWidth)
                .onAppear {
                    fillWidth = maxWidth
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: height / 2))
    }
}


