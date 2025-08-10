//
//  GoalsView.swift
//  Calify
//
//  Created by christopher on 8/10/25.
//

import SwiftUI

struct GoalsView: View {
    @State private var profile: Profiles? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            if let profile = profile {
                GoalsCardView(
                    userId: profile.id?.uuidString ?? "unknown",
                    cal: profile.cal_goal ?? 2000,
                    protein: profile.protein_goal ?? 50,
                    carbs: profile.carb_goal ?? 250,
                    fat: profile.fat_goal ?? 70
                )
            } else {
                ProgressView("Loading...")
            }
        }
        .padding()
        .gradientBackground()
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.large)
        .task {
            print("🌀 .task started in GoalsView")

            if profile == nil {
                do {
                    let result = try await SupabaseManager.shared.getProfilesInfo()
                    print("result")
                    if let loadedProfile = result {
                        print("✅ Profile loaded: \(loadedProfile)")
                        profile = loadedProfile
                    } else {
                        print("⚠️ Supabase returned nil profile")
                    }
                } catch {
                    print("❌ Failed to fetch profile: \(error)")
                }
            } else {
                print("ℹ️ Profile already loaded")
            }
        }
    }
}
