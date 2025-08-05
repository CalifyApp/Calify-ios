//
//  Logs.swift
//  Calify
//
//  Created by justin lorenzo on 8/4/25.
//

import SwiftUI

struct MealLogs: View {
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @State private var showingDeleteAlert = false
    @State private var mealToDelete: MealEstimate? = nil
    @Binding var currentDate: Date
    let isToday: Bool

    var body: some View {
        VStack(spacing: 8) {
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Logs")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVStack(spacing: 8) {
                        ForEach(nutritionManager.getMeals(for: currentDate), id: \.id) { meal in
                            SwipeableRow(
                                meal: meal,
                                onDelete: {
                                    mealToDelete = meal
                                    showingDeleteAlert = true
                                },
                                currentDate: $currentDate
                            )
                            .padding(.bottom, 30)
                            
                        }
                    }
                    .padding()
                }
                
            }
        }
        .alert("Are you sure you want to delete?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                mealToDelete = nil
            }
            Button("Delete", role: .none) {
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
struct SwipeableRow: View {
    let meal: MealEstimate
    let onDelete: () -> Void

    @Binding var currentDate: Date
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    private let deleteButtonWidth: CGFloat = 80
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack(alignment: .trailing) {
            // Background Delete Button (always aligned to trailing)
            HStack {
                Spacer()
                Button(action: {
                    hapticFeedback.impactOccurred()
                    onDelete()
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .frame(width: deleteButtonWidth, height: 80)
                        .background(Color.red)
                        .cornerRadius(12)
                }
                
            }

            // Foreground swipeable card
            MealCard(meal: meal, onDelete: {
                nutritionManager.refresh(for: currentDate)
            })
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            let dragAmount = value.translation.width
                            if abs(dragAmount) > deleteButtonWidth {
                                let resistance = (abs(dragAmount) - deleteButtonWidth) * 0.5
                                offset = -(deleteButtonWidth + resistance)
                            } else {
                                offset = dragAmount
                            }
                            isDragging = true
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if value.translation.width < -50 {
                                offset = -deleteButtonWidth
                                hapticFeedback.impactOccurred()
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if offset < 0 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 80)
        
    }
}
