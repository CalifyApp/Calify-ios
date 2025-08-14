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
    @State private var currentDate: Date = Date()
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @EnvironmentObject var profileManager: ProfileManager
    @State private var showMealSheet = false
    @State private var activeSheet: ActiveSheet?

    var body: some View {
        
//        switch currentView {
//        case .home:
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        DateNav(selectedDate: $currentDate, nutritionManager: nutritionManager)
                        
                        if let profile = profileManager.profile {
                            MacroOverview(profile: profile, selectedDate: $currentDate)
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
                    AddMeal(selectedDate: $currentDate)
                        .presentationDetents([.large])
                        .presentationCornerRadius(24)
                case .mealDetail(let meal):
                    MealDetailView(meal: meal)
            }
            }
            .task {
                await profileManager.loadProfile()
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
