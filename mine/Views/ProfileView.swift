//
//  ProfileView.swift
//  Calify
//
//  Created by christopher on 3/29/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var streakManager: StreakManager
    @State private var profile: Profiles? = nil
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    
    var body: some View {
        Text("Welcome! You are currently signed in as a guest. Login feature coming soon...")
        Button("Reset Streak") {
            streakManager.resetStreakForTesting()
        }
   
        VStack(spacing: 16) {
            Text("Welcome! You are currently signed in as a guest. Login feature coming soon...")
            if let profile = profile {
                GoalsCardView(
                    userId: profile.id?.uuidString ?? "unknown",
                    cal: profile.cal_goal ?? 2000,
                    protein: profile.protein_goal ?? 50,
                    carbs: profile.carb_goal ?? 250,
                    fat: profile.fat_goal ?? 70,
                    currentCal: nutritionManager.todaysTotal?.totalCalories ?? 0, // nutritionManager.todaysTotal?.totalCalories
                    currentProtein: nutritionManager.todaysTotal?.totalProtein ?? 0,
                    currentCarbs: nutritionManager.todaysTotal?.totalCarbs ?? 0,
                    currentFat: nutritionManager.todaysTotal?.totalFat ?? 0
                )
            } else{
                ProgressView("Loading...")
            }
            
        }
        Text("Current Streak: \(streakManager.currentStreak)")

    }
}

#Preview {
    ProfileView()
}
