import SwiftUI

/**
 struct PressableCardLink: View {
     var item: Item

     @State private var isPressed = false

     var body: some View {
         NavigationLink(destination: DetailView(item: item)) {
             VStack(alignment: .leading) {
                 Text(item.title)
                     .font(.headline)
                 Text(item.subtitle)
                     .font(.subheadline)
             }
             .padding()
             .background(isPressed ? Color.gray.opacity(0.2) : Color.white)
             .cornerRadius(8)
             .shadow(radius: 1)
             .scaleEffect(isPressed ? 0.98 : 1.0)
         }
         .simultaneousGesture(
             DragGesture(minimumDistance: 0)
                 .onChanged { _ in isPressed = true }
                 .onEnded { _ in
                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                         isPressed = false
                     }
                 }
         )
     }
 }
 
 
 
 
 
 */


struct TodayView: View {
    
    @EnvironmentObject var nutritionManager: DailyNutritionManager
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

                if nutritionManager.isLoading {
                    ProgressView("Loading your meals...")
                } else if let error = nutritionManager.errorMessage {
                    ContentUnavailableView("Couldn't Load Meals", systemImage: "exclamationmark.triangle", description: Text(error))
                        .padding()
                } else if nutritionManager.todaysMeals.isEmpty {
                    ContentUnavailableView("No Meals Today", systemImage: "fork.knife", description: Text("Meals you add will appear here"))
                } else {
                    
                    List {
                       
                        if let summary = nutritionManager.todaysTotal {
                            ZStack {
                                DailySummaryCard(summary: summary)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .background(Color(.secondarySystemBackground)
                                .cornerRadius(12))
                        }
                    
                        Text(isToday ? "Today's Meals" : "\(formattedDate)'s Meals")
                            .font(.headline)
                            .padding(.horizontal, 4)
                            .padding(.top, 12)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        
                        
                        ForEach(nutritionManager.todaysMeals, id: \.description) { meal in
                            ZStack {
                                MealCard(meal: meal, onDelete: {
                                    nutritionManager.refresh(for: currentDate)
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
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 4)
                        }
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
                                MealCacheManager.shared.removeMeal(withId: id)
                                nutritionManager.todaysMeals = MealCacheManager.shared.getRecentMeals()
                                nutritionManager.todaysTotal = aggregateMeals(meals: nutritionManager.todaysMeals)
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
                        nutritionManager.refresh(for: currentDate)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                nutritionManager.refresh(for: currentDate)
            }
        }
    }
    
    
    //update current day to previous day
    func navigateToPreviousDay() {
        guard !isAtSevenDayLimit else { return } //if we at the back limit, return (theoretically we never hit this bc it wont show in ui)
        
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) { //newDate = calendars cur date - 1. if this is true...
            currentDate = newDate //then currentDate = new Date
            nutritionManager.refresh(for: currentDate) //refresh the data, this time, it will display current days meals, because we refresh data with current date state, getting new meal data
        }
    }
    
    //navigate to next day updates current day to next day
    func navigateToNextDay() {
        guard !isToday else { return }
        
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
            let today = Calendar.current.startOfDay(for: Date())
            if newDate <= today {
                currentDate = newDate
                nutritionManager.refresh(for: currentDate)
            } else {
                currentDate = today
                nutritionManager.refresh(for: currentDate)
            }
        }
    }
}


//#Preview {
//    TodayView()
//}
