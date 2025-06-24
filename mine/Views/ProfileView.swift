//
//  ProfileView.swift
//  Calify
//
//  Created by christopher on 3/29/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var streakManager: StreakManager

    var body: some View {
        Text("Welcome! You are currently signed in as a guest. Login feature coming soon...")
        Button("Reset Streak") {
            streakManager.resetStreakForTesting()
        }
        Text("Current Streak: \(streakManager.currentStreak)")

    }
}

#Preview {
    ProfileView()
}
