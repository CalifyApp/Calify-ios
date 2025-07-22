//
//  ProfileView.swift
//  Calify
//
//  Created by christopher on 3/29/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var profile: Profiles? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome! You are currently signed in as a guest. Login feature coming soon...")
            if let profile = profile {
                GoalsCardView(
                    userId: profile.id?.uuidString ?? "unknown",
                    cal: profile.cal_goal ?? 2000,
                    protein: profile.protein_goal ?? 50,
                    carbs: profile.carb_goal ?? 250,
                    fat: profile.fat_goal ?? 70,
                )
            } else{
                ProgressView("Loading...")
            }
            
        }
        .padding()
        .task {
            print("🌀 .task started in ProfileView")

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

