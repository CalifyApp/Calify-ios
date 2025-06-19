import SwiftUI

struct TodayView: View {
    @State private var todaysMeals: [MealEstimate] = []
    @State private var todaysTotal: NutrientTotals? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var mealToDelete: MealEstimate? = nil
    @State private var showingDeleteAlert = false
    @State private var currentDate = Date() //Track current displayed date. what current date are we on/displaying?

    private var isToday: Bool {
        Calendar.current.isDateInToday(currentDate)
    }
    
    private var isAtSevenDayLimit: Bool { //we wanna check if we are at the 7 day limit always.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let limit = calendar.date(byAdding: .day, value: -7, to:  today)!
        return calendar.startOfDay(for: currentDate) <= limit
    }
    
    //this is just formatting the date ex: Apr 12, 2025 
    private var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: currentDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading your meals...")
                } else if let error = errorMessage {
                    ContentUnavailableView("Couldn't Load Meals", systemImage: "exclamationmark.triangle", description: Text(error))
                        .padding()
                } else if todaysMeals.isEmpty {
                    ContentUnavailableView("No Meals Today", systemImage: "fork.knife", description: Text("Meals you add will appear here"))
                } else {
                    List {
                       
                        if let summary = todaysTotal {
                            ZStack {
                                DailySummaryCard(summary: summary)
                            }

                        }


                    
                        Text(isToday ? "Today's Meals" : "\(formattedDate)'s Meals")
                            .font(.headline)
                            .padding(.horizontal, 4)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                            .listRowInsets(EdgeInsets()) // Remove system padding
                            .listRowBackground(Color.clear)
                        
                        
                        ForEach(todaysMeals, id: \.description) { meal in
                            ZStack {
                                MealCard(meal: meal, onDelete: {
                                    refreshData()
                                })
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .none) {
                                        mealToDelete = meal
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)

                                NavigationLink(destination: MealDetailView(meal: meal)) {
                                    EmptyView()
                                }
                                
                                .buttonStyle(.plain)
                                .opacity(0)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 4) // spacing between cards
                        }
//                        .onDelete(perform: deleteMeals)
                        
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .alert("Are you sure you want to delete?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    mealToDelete = nil
                }
                Button("Delete", role: .none) {
                    if let meal = mealToDelete, let id = meal.id {
                        Task {
                            await SupabaseManager.shared.deleteMeal(id: id)
                            await MainActor.run {
                                todaysMeals.removeAll { $0.id == id }
                                refreshData()
                            }
                            mealToDelete = nil
                        }
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .navigationTitle(isToday ? "Today's Nutrition" : formattedDate)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navigateToPreviousDay()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Previous Day")
                        }
                    }
                    .disabled(isAtSevenDayLimit)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if !isToday {
                            Button {
                                navigateToNextDay()
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Next Day")
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                    }
                    Button {
                        refreshData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                refreshData()
            }
        }
    }
    
    
    //update current day to previous day
    func navigateToPreviousDay() {
        guard !isAtSevenDayLimit else { return } //if we at the back limit, return (theoretically we never hit this bc it wont show in ui)
        
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) { //newDate = calendars cur date - 1. if this is true...
            currentDate = newDate //then currentDate = new Date
            refreshData() //refresh the data, this time, it will display current days meals, because we refresh data with current date state, getting new meal data
        }
    }
    
    //navigate to next day updates current day to next day
    func navigateToNextDay() {
        guard !isToday else { return }
        
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
            let today = Calendar.current.startOfDay(for: Date())
            if newDate <= today {
                currentDate = newDate
                refreshData()
            } else {
                currentDate = today
                refreshData()
            }
        }
    }

    
    func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let meals = try await SupabaseManager.shared.fetchMeals(for: currentDate)
                await MainActor.run { //main actor forces main thread. without this, it will run on any thread, which isnt allowed (need immediate state/UI updates)
                    todaysMeals = meals
                    todaysTotal = aggregateMeals(meals: meals)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error loading meals: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DailySummaryCard: View {
    var summary: NutrientTotals
    
    var body: some View {
        VStack(spacing: 16) {
            // Calories
            VStack(spacing: 4) {
                Text("\(summary.totalCalories)")
                    .font(.system(size: 36, weight: .bold))
                Text("CALORIES")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Divider
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
                .padding(.horizontal)
            
            // Macros
            HStack(spacing: 24) {
                MacroItem(value: summary.totalProtein, label: "Protein", color: .blue)
                MacroItem(value: summary.totalCarbs, label: "Carbs", color: .green)
                MacroItem(value: summary.totalFat, label: "Fat", color: .orange)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

struct MacroItem: View {
    var value: Int
    var label: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)g")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}

struct MealCard: View {
    @State private var showDeleteConfirmation = false
    var meal: MealEstimate
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with meal description and delete button
            HStack {
                Text(meal.description)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                    .padding(8)
//                    .background(Circle().fill(Color.gray.opacity(0.2)))
            }
            
            // Nutrition section
            HStack(alignment: .center, spacing: 16) {
                // Calories display
                VStack(spacing: 0) {
                    Text("\(meal.calories)")
                        .font(.system(size: 24, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Divider()
                    .frame(height: 40)

                // Equal-width macros
                HStack(spacing: 12) {
                    MacroNutrient(value: meal.protein, label: "protein", color: .blue)
                    MacroNutrient(value: meal.carbs, label: "carbs", color: .green)
                    MacroNutrient(value: meal.fat, label: "fat", color: .orange)
                }

                // Limit the size of the accuracy gauge
                ScoreGaugeView(
                    score: meal.accuracyScore,
                    title: "accuracy"
                )
                .frame(maxWidth: 80) // limit how wide it can go
            }
            
        }

        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Simplified macro nutrient display
struct MacroNutrient: View {
    var value: Int
    var label: String
    var color: Color
    
    var body: some View {
           VStack(spacing: 2) {
               Text("\(value)g")
                   .font(.system(size: 16, weight: .semibold))
                   .foregroundColor(color)
                   .lineLimit(1)
                   .minimumScaleFactor(0.75)

               Text(label)
                   .font(.caption2)
                   .foregroundColor(.secondary)
                   .lineLimit(1)
                   .minimumScaleFactor(0.75)
           }
           .frame(maxWidth: .infinity) // Makes all macros equal width
       }
}


struct NutritionPill: View {
    var value: Int
    var unit: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
        .foregroundColor(color)
    }
}

//#Preview {
//    TodayView()
//}
