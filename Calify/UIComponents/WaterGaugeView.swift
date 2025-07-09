//
//  WaterGaugeView.swift
//  Calify
//
//  Created by justin lorenzo on 6/20/25.
//
import SwiftUI

struct WaterGaugeView: View {
    let currentIntake: Int
    @State private var goal: Int = WaterTrackerStorage.loadGoal()
    @State private var showingGoalSheet = false
    @State private var newGoalInput = ""

    var progress: Double {
        min(Double(currentIntake) / Double(goal), 1.0)
    }

    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .foregroundColor(Color.gray.opacity(0.3))
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
                    .foregroundColor(.gray)
            }

            VStack {
                Spacer()
                (
                    Text("Goal: ")
                        .foregroundColor(.gray)
                    + Text("\(goal) oz")
                        .foregroundColor(.blue)
                )
                .font(.system(size: 16, weight: .medium))
                .padding(.bottom, 24)
                .onTapGesture {
                    newGoalInput = "\(goal)"
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
                        goal = newGoal
                        WaterTrackerStorage.saveGoal(newGoal)
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
            .padding()
        }
    }
}
