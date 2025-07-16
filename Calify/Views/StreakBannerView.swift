//
//  StreakView.swift
//  Calify
//
//  Created by justin lorenzo on 7/16/25.
//
import SwiftUI
struct StreakBannerView: View {
    let currentStreak: Int
    let maxDays = 7

    var body: some View {
        let calculatedStreak = currentStreak % maxDays
        let visibleStreak = calculatedStreak == 0 ? maxDays : calculatedStreak

        VStack(spacing: 6) {
            Text("Day \(visibleStreak) Streak!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack {
                ForEach(1...maxDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text("\(day)")
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .medium))

                        Image(systemName: day <= visibleStreak ? "flame.fill" : "flame")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 20)
                        
                    }
                    .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 8)
        .padding(.horizontal, 14)
        .padding(.top, 30)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
