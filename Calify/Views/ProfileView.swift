////
////  ProfileView.swift
////  Calify
////
////  Created by christopher on 3/29/25.
////
///
import SwiftUI

struct ProfileView: View {
    @State private var navigationCards: [NavigationCardData] = [
        NavigationCardData(id: UUID(), title: "Contact Us"),
        NavigationCardData(id: UUID(), title: "Nutrient Goals")
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Personal Details Card (always at top)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Personal Details")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // Stats Grid
                    HStack(spacing: 0) {
                        // Left Column
                        VStack(spacing: 20) {
                            StatItemView(
                                icon: "ruler",
                                iconColor: .blue,
                                title: "Height",
                                value: "5'10\""
                            )
                            
                            StatItemView(
                                icon: "calendar",
                                iconColor: .orange,
                                title: "Age",
                                value: "28"
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Column
                        VStack(spacing: 20) {
                            StatItemView(
                                icon: "scalemass",
                                iconColor: .green,
                                title: "Weight",
                                value: "170 lbs"
                            )
                            
                            StatItemView(
                                icon: "person",
                                iconColor: .purple,
                                title: "Gender",
                                value: "Male"
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Dynamic Navigation Cards
                ForEach(navigationCards) { card in
                    NavigationCardView(title: card.title)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            
        } .gradientBackground()
    }
    
}

struct NavigationCardData: Identifiable {
    let id: UUID
    let title: String
}

struct StatItemView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
    }
}

struct NavigationCardView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

//
//import SwiftUI
//
//struct ProfileView: View {
//    @State private var profile: Profiles? = nil
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Welcome! You are currently signed in as a guest. Login feature coming soon...")
//            if let profile = profile {
//                GoalsCardView(
//                    userId: profile.id?.uuidString ?? "unknown",
//                    cal: profile.cal_goal ?? 2000,
//                    protein: profile.protein_goal ?? 50,
//                    carbs: profile.carb_goal ?? 250,
//                    fat: profile.fat_goal ?? 70
//                )
//            } else{
//                ProgressView("Loading...")
//            }
//            
//        }
//        .padding()
//        .gradientBackground()
//        .task {
//            print("🌀 .task started in ProfileView")
//
//                if profile == nil {
//                    do {
//                        let result = try await SupabaseManager.shared.getProfilesInfo()
//                        print("result")
//                        if let loadedProfile = result {
//                            print("✅ Profile loaded: \(loadedProfile)")
//                            profile = loadedProfile
//                        } else {
//                            print("⚠️ Supabase returned nil profile")
//                        }
//                    } catch {
//                        print("❌ Failed to fetch profile: \(error)")
//                    }
//                } else {
//                    print("ℹ️ Profile already loaded")
//                }
//            }
//
//        }
//    }
//
