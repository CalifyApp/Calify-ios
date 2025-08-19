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
    @Binding var goToChild: ProfileChild
    @State private var currentDate: Date = Date()
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @EnvironmentObject var profileManager: ProfileManager
    @State private var showMealSheet = false
    @State private var activeSheet: ActiveSheet?
    @State private var submissionError: String? = nil
    private let generator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        DateNav(selectedDate: $currentDate, nutritionManager: nutritionManager)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                

                        if let profile = profileManager.profile {
                            MacroOverview(profile: profile, selectedDate: $currentDate) {
                                selectedTab = 3
                                generator.impactOccurred()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    goToChild = .nutrientGoals
                                }
                            }
                            .environmentObject(nutritionManager)
                        }
                        
                        MealLogs(
                            onMealSelected: { meal in
                                generator.impactOccurred()
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
                        .presentationDetents([.medium])
                        .presentationCornerRadius(24)
                case .mealDetail(let meal):
                    MealDetailView(meal: meal)
                }
            }
            .task {
                await profileManager.loadProfile()
            }
    }
    
}
