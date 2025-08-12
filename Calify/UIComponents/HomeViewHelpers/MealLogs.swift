//
//  Logs.swift
//  Calify
//
//  Created by justin lorenzo on 8/4/25.
//

import SwiftUI

struct MealLogs: View {
    
    let onMealSelected: (MealEstimate) -> Void
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @State private var showingDeleteAlert = false
    @State private var mealToDelete: MealEstimate? = nil
    @Binding var currentDate: Date
    @State private var viewHeight: CGFloat = 0
    let isToday: Bool

    var body: some View {
             
        VStack(spacing: 0) {
            if nutritionManager.isLoading {
                ProgressView("Loading your meals...")
                    .padding(.top)
            } else if let error = nutritionManager.errorMessage {
                ContentUnavailableView("Couldn't Load Meals", systemImage: "exclamationmark.triangle", description: Text(error))
                    .padding()
            } else if nutritionManager.getMeals(for: currentDate).isEmpty {
                ContentUnavailableView("No Meals", systemImage: "fork.knife", description: Text("Meals you add will appear here."))
                    .padding(.top)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Logs")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(nutritionManager.loadingMeals, id: \.self) { _ in
                            MealLoading()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(uiColor: .secondarySystemBackground))
                                        .shadow(radius: 1)
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                        }
                        .padding(.vertical, 4)
                        
                        ForEach(nutritionManager.getMeals(for: currentDate), id: \.id) { meal in
                            
                            MealCard(meal: meal, onDelete: {
                                nutritionManager.refresh(for: currentDate)
                            })
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                                    .shadow(radius: 1)
                            )
                            .onTapGesture {
                                onMealSelected(meal)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .none) {
                                    mealToDelete = meal
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            
                            
                        }
                        .padding(.vertical, 4)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .listStyle(InsetGroupedListStyle())
                    //.frame(/*CGFloat(nutritionManager.getMeals(for: currentDate).count + nutritionManager.loadingMeals.count) * 155*/) // change
                    .frame(minHeight: CGFloat(130 * (nutritionManager.getMeals(for: currentDate).count + nutritionManager.loadingMeals.count)) + 25)
                    .scrollDisabled(true)
                    .padding(.top, -30)
                }
            }
        }
        .alert("Are you sure you want to delete?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                mealToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete, let id = meal.id, let created_at = meal.created_at {
                    Task {
                        await SupabaseManager.shared.deleteMeal(id: id)
                        await MainActor.run {
                            MealCacheManager.shared.removeMeal(withId: id, on: created_at)
                            
                            let currentMeals = nutritionManager.getMeals(for: currentDate).filter { $0.id != id }
                            let key = nutritionManager.dateKey(for: currentDate)
                            nutritionManager.dailyTotals[key] = aggregateMeals(meals: currentMeals)
                        }
                        mealToDelete = nil
                    }
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            nutritionManager.refresh(for: currentDate)
        }
        
    }
}
