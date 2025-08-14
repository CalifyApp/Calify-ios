//
//  HomeView.swift
//  Calify
//
//  Created by justin lorenzo on 8/4/25.
//

import SwiftUI

//enum ViewState {
//    case home
//    case mealDetail(MealEstimate)
//}

enum ActiveSheet: Identifiable {
    case addMeal
    case mealDetail(MealEstimate)
    
    var id: Int {
        switch self {
        case .addMeal: return 0
        case .mealDetail: return 1
        }
    }
}

struct HomeView: View {
    
    @Binding var selectedTab: Int
    @State private var currentDate: Date = Date()
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @State private var profile: Profiles? = nil
    @State private var showMealSheet = false
    @State private var activeSheet: ActiveSheet?
    @State private var submissionError: String? = nil

    var body: some View {
        
//        switch currentView {
//        case .home:
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        DateNav(selectedDate: $currentDate, nutritionManager: nutritionManager)
                        
                        if let profile = profile {
                            MacroOverview(profile: profile, selectedDate: $currentDate) {
                                if Calendar.current.isDate(currentDate, inSameDayAs: Date()) {
                                    selectedTab = 2
                                }
                            }
                                .environmentObject(nutritionManager)
                        }
                        
                        MealLogs(
                            onMealSelected: { meal in
                                activeSheet = .mealDetail(meal)
                            },
                            currentDate: $currentDate,
                            isToday: Calendar.current.isDateInToday(currentDate)
                        )
                        
                    }
                    .padding(.vertical)
                }
                
                VStack {
                    Spacer()
                    AddMealButton {
                        activeSheet = .addMeal
                    }
                }
            }
            .gradientBackground()
            .sheet(item: $activeSheet) { item in
                switch item {
                case .addMeal:
                    AddMeal(selectedDate: $currentDate, submissionError: $submissionError)
                        .presentationDetents([.large])
                        .presentationCornerRadius(24)
                case .mealDetail(let meal):
                    MealDetailView(meal: meal)
                }
            }
            .overlay(
                Group {
                    if let error = submissionError {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                Text(error)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .padding(.horizontal)
                            }
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(12)
                            .padding(.bottom, 30)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onTapGesture { submissionError = nil }
                        }
                        .animation(.easeInOut, value: submissionError)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    submissionError = nil
                                }
                            }
                        }
                    }
                }
            )

            .onAppear {
                print("////////\(currentDate)")
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
//        case .mealDetail(let meal):
//            MealDetailView(meal: meal)
//                .transition(.move(edge: .trailing))
//                .onDisappear {
//                    currentView = .home
//            }
//        }
    }
    
}
