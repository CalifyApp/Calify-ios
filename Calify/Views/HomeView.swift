//
//  HomeView.swift
//  Calify
//
//  Created by justin lorenzo on 8/4/25.
//

import SwiftUI

struct HomeView: View {
    @State private var currentDate: Date = Date()
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @State private var profile: Profiles? = nil
    @State private var showMealSheet = false

    var body: some View {
        
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    DateNav(selectedDate: $currentDate, nutritionManager: nutritionManager)

                    if let profile = profile {
                        MacroOverview(profile: profile, selectedDate: $currentDate)
                            .environmentObject(nutritionManager)
                    }

                    MealLogs(currentDate: $currentDate, isToday: Calendar.current.isDateInToday(currentDate))
                }
                .padding(.vertical)
            }
            
            VStack {
                Spacer()
                AddMealButton {
                    showMealSheet = true
                }
            }
        }
        .gradientBackground()
        .sheet(isPresented: $showMealSheet) {
            OldHomeView()
                .presentationDetents([.large])
                .presentationCornerRadius(24)
        }
        .task {
            if profile == nil {
                do {
                    let result = try await SupabaseManager.shared.getProfilesInfo()
                    if let loadedProfile = result {
                        profile = loadedProfile
                    } else {
                        print("⚠️ Supabase returned nil profile")
                    }
                } catch {
                    print("❌ Failed to fetch profile: \(error)")
                }
            }
        }
    }
    
}
