//
//  AddMeal.swift
//  Calify
//
//  Created by justin lorenzo on 8/5/25.
//

import SwiftUI

struct AddMeal: View {
    
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var nutritionManager: DailyNutritionManager
    @State private var userMeal: String = ""
    @State private var toggleRecord = false
    @State private var result: MealEstimate? = nil
    @State private var isMealLimitReached = false
    @FocusState private var isTextFieldFocused: Bool
    private let speechRecognizer = SpeechRecognizer()
    
    private func handleRecordingToggle() {
        if toggleRecord {
            userMeal = ""
            speechRecognizer.startRecognition { recognizedText in
                DispatchQueue.main.async {
                    self.userMeal = recognizedText
                }
            }
        }
        
        if toggleRecord == false {
            speechRecognizer.stopRecognition()
            if !userMeal.isEmpty {
                let tempID = UUID()
                let mealDate = selectedDate
                submitMeal(tempID: tempID, mealDate: mealDate)
            }
        }
    }
    
    private func checkMealLimit() {
        Task {
            do {
                isMealLimitReached = try await SupabaseManager.shared.mealLimit()
            } catch {
                print("⚠️ Failed to check meal limit: \(error)")
                isMealLimitReached = false
            }
        }
    }
    
    private func submitMeal(tempID: UUID, mealDate: Date) {
        guard !userMeal.isEmpty else { return }
        
        Task {
            do {
                let jsonMealEstimatesResult = await SupabaseManager.shared.callOpenAI(meal: userMeal)
                
                switch jsonMealEstimatesResult {
                case .success(let jsonMealEstimatesString):
                    if let data = jsonMealEstimatesString.data(using: .utf8) {
                        do {
                            let decoded = try JSONDecoder().decode(MealEstimate.self, from: data)
                            result = decoded
                            print(decoded) //print the json received from chatgpt
                        } catch {
                            print("Decoding failed: \(error)")
                        }
                    }
                case .failure(let error):
                    print("API Error: \(error.localizedDescription)")
                }
                userMeal = ""
            }
            
            do {
                if let result = result {
                    try await SupabaseManager.shared.insertMeal(
                        description: result.description,
                        calories: result.calories,
                        protein: result.protein,
                        carbs: result.carbs,
                        fat: result.fat,
                        accuracyScore: result.accuracyScore,
                        tips: result.tips,
                        created_at: mealDate
                    )
                    nutritionManager.removeLoadingMeal(for: mealDate, id: tempID)

                    
                    DispatchQueue.main.async {
                        nutritionManager.refresh(for: mealDate)
                    }
                }
            }
            catch let error {
                print("Error Inserting Meal \(error)")
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }
            
            VStack(spacing:30) {
                Spacer()
                
                Text("What did you eat?")
                    .font(.title)
                    .fontWeight(.bold)
                
                Button {
                    toggleRecord = !toggleRecord
                    handleRecordingToggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(toggleRecord ? Color.red.opacity(0.8) : Color.blue)
                            .frame(width: 120, height: 120)
                            .shadow(radius: 5)
                        if toggleRecord {
                            Circle()
                                .stroke(Color.red, lineWidth: 3)
                                .frame(width: 140, height: 140)
                                .scaleEffect(toggleRecord ? 1.2 : 1.0)
                                .opacity(toggleRecord ? 0.0 : 1.0)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: toggleRecord)
                            
                            Text("Stop")
                                .font(.headline)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                Text(userMeal.isEmpty ? "Tap the mic button to start logging your meal..." : "\"" + userMeal + "\"")
                    .foregroundColor(userMeal.isEmpty ? .gray : .primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack {
                    TextField("Or type your meal here...", text: $userMeal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .focused($isTextFieldFocused)
                    
                    Button {
                        let tempID = UUID()
                        let mealDate = selectedDate
                        nutritionManager.insertPlaceholderMeal(for: mealDate, tempID: tempID)
                        dismiss()
                        submitMeal(tempID: tempID, mealDate: mealDate)
                        isTextFieldFocused = false

                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                    .disabled(isMealLimitReached || userMeal.isEmpty)
                }
                
            }
            
            if isMealLimitReached {
                Text("Meal limit of 15 reached! Please delete a meal if you'd like to add a new one.")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.top)
            }
            
            Spacer()
        }
        .onAppear { checkMealLimit() }
        .padding()
    }
}
