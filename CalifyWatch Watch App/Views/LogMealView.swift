import SwiftUI

struct LogMealView: View {
    @State private var userMeal: String = ""
    @State private var isLoading = false
    @State private var toggleRecord = false
    @State private var result: MealEstimate? = nil
    @State private var showResult = false
    @State private var showSuccess = false // New state for success animation
    @State private var showFailure = false // Add this with your other state variables

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 20){
                Text("Log your meal")
                    .font(.headline)
                
                TextField("Describe your meal...", text: $userMeal)
                
                Button {
                    submitMeal()
                } label: {
                    Group {
                        if isLoading {
                            // Loading animation
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.2)
                        } else {
                            // Default arrow
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 70, height: 70) // Consistent size for all states
                }
                .padding(.trailing)
                .disabled(userMeal.isEmpty || isLoading)
            }
            .padding()
            
            // Full-screen success overlay
            if showSuccess {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                                                    CheckMarkView(animate: true)
                                                    Text("Meal Saved!")
                                                        .font(.title2)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.white)
                                                }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showSuccess)
            }
            // Add this after your success overlay, still inside the ZStack
            if showFailure {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                            Text("Failed to Save Meal")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("Please try again")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showFailure)
            }

        }
    }
    
    private func submitMeal() {
        guard !userMeal.isEmpty else { return }
        
        isLoading = true
        showSuccess = false // Reset success state
        
        Task {
            let jsonMealEstimatesResult = await WatchSupabaseManager.shared.callOpenAI(meal: userMeal)
            
            switch jsonMealEstimatesResult {
            case .success(let jsonMealEstimatesString):
                if let data = jsonMealEstimatesString.data(using: .utf8) {
                    do {
                        let decoded = try JSONDecoder().decode(MealEstimate.self, from: data)
                        result = decoded
                        showResult = true
                        print(decoded)
                    } catch {
                        print("Decoding failed: \(error)")
                    }
                }
            case .failure(let error):
                print("API Error: \(error)")
            }
            
            // Insert meal into database
            do {
                try await WatchSupabaseManager.shared.insertMeal(
                    accessToken: UserDefaults.standard.string(forKey: "accessToken") ?? "",
                    description: result?.description ?? "",
                    calories: result?.calories ?? 0,
                    protein: result?.protein ?? 0,
                    carbs: result?.carbs ?? 0,
                    fat: result?.fat ?? 0,
                    accuracyScore: result?.accuracyScore ?? 0,
                    tips: result?.tips ?? [""]
                )
                await MainActor.run {
                                isLoading = false
                                showSuccess = true
                                userMeal = ""
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    showSuccess = false
                                }
                            }

            } catch {
                //First attempt failed, try requesting tokens and retry
                WatchSessionManager.shared.requestTokensFromiPhone()
                
                do {
                    try await WatchSupabaseManager.shared.insertMeal(
                        accessToken: UserDefaults.standard.string(forKey: "accessToken") ?? "",
                        description: result?.description ?? "",
                        calories: result?.calories ?? 0,
                        protein: result?.protein ?? 0,
                        carbs: result?.carbs ?? 0,
                        fat: result?.fat ?? 0,
                        accuracyScore: result?.accuracyScore ?? 0,
                        tips: result?.tips ?? [""]
                    )
                    await MainActor.run {
                                    isLoading = false
                                    showSuccess = true
                                    userMeal = ""
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        showSuccess = false
                                    }
                                }
                    

                } catch {
                    //Both attempts failed if we reach here
                    print("both primary and fallback insertion failed. \(error)")
                    await MainActor.run {
                        isLoading = false
                        showFailure = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                showFailure = false
                                            }

                    }
                    
                }
            }
        }
    }
}
