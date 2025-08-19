//
//  WaterGaugeView.swift
//  Calify
//
//  Created by justin lorenzo on 6/20/25.
//
import SwiftUI

struct WaterGaugeView: View {
    
    
    let currentIntake: Int
    @EnvironmentObject var waterManager: WaterManager
    @State private var showingGoalSheet = false
    @State private var newGoalInput = ""

    var progress: Double {
        min(Double(currentIntake) / Double(waterManager.goal), 1.0)
    }

    var body: some View {
        ZStack {
            
            // Background arc
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .foregroundColor(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.2), radius: 2)
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(90))

            // Progress arc
            Circle()
                .trim(from: 0.15, to: 0.15 + 0.7 * progress)
                .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .foregroundColor(.blue)
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(90))
                .animation(.easeOut(duration: 1), value: currentIntake)

            VStack(spacing: 6) {
                Text("\(currentIntake)")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundColor(.primary)

                Text("ounces")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
            }

            VStack {
                Spacer()
                (
                    Text("Goal: ")
                        .foregroundColor(.white)
                    + Text("\(waterManager.goal) oz")
                        .foregroundColor(.blue)
                )
                .font(.system(size: 16, weight: .medium))
                .padding(.bottom, 24)
                .onTapGesture {
                    newGoalInput = "\(waterManager.goal)"
                    showingGoalSheet = true
                }
            }
            .frame(width: 240, height: 240)
        }
        .sheet(isPresented: $showingGoalSheet) {
            VStack(spacing: 24) {
                Text("Set New Daily Goal")
                    .font(.title3)
                    .padding(.top)

                TextField("Enter goal in oz", text: $newGoalInput)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .frame(width: 200)

                Button("Set Goal") {
                    if let newGoal = Int(newGoalInput), newGoal > 0 {
//                        goal = newGoal
//                        WaterTrackerStorage.saveGoal(newGoal)
                        waterManager.saveGoal(newGoal)
                        showingGoalSheet = false
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)

                Spacer()
            }
            .presentationDetents([.fraction(0.3)])
            .presentationCornerRadius(24)
            .padding()
        }
    }
}
