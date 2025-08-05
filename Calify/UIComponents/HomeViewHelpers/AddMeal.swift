//
//  AddMeal.swift
//  Calify
//
//  Created by justin lorenzo on 8/5/25.
//

import SwiftUI

struct AddMeal: View {
    @Binding var showSheet: Bool
    @State private var userMeal: String = ""
    @State private var isLoading = false
    @State private var toggleRecord = false
    @State private var result: MealEstimate? = nil
    @State private var showResult = false
    @State private var errorMessage: String? = nil
    private let speechRecognizer = SpeechRecognizer()

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Button {
                if toggleRecord {
                    toggleRecord = false
                }
                else {
                    toggleRecord = true
                }
                handleRecordingToggle()
            }
            label: {
                ZStack {
                    Circle()
                        .fill(toggleRecord ? Color.red.opacity(0.8) : Color.blue)
                        .frame(width: 120, height: 120)
                        .shadow(radius: 5)
                    
                    if toggleRecord {
                        // Pulsating animation when recording
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

            TextField("e.g. Chicken sandwich and fries", text: $userMeal)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button {
                submitMeal()
                

            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding(.trailing)
            
            if isLoading {
                LoadingView()
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.bottom)
        .navigationDestination(isPresented: $showResult) {
            if let result = result {
                MealResultView(result: result)
            } else {
                MealResultView(result: MealEstimate(id: nil, user_id: nil, protein: 0, carbs: 0, fat: 0, calories: 0, description: "", accuracyScore: 0, accuracyFeedback: nil, created_at: nil, tips: []))
            }
        }
    }
    
    private func handleRecordingToggle() {
        // Start recording
        if toggleRecord {
            userMeal = ""
            speechRecognizer.startRecognition { recognizedText in
                DispatchQueue.main.async {
                    self.userMeal = recognizedText
                }
            }
        }
        
        if toggleRecord == false {
            // Stop recording
            speechRecognizer.stopRecognition()
            if !userMeal.isEmpty {
                submitMeal()
            }
        }
    }

    private func submitMeal() {
        guard !userMeal.isEmpty else { return }
        
        isLoading = true
        
        
        Task {
            let jsonMealEstimatesResult = await SupabaseManager.shared.callOpenAI(meal: userMeal)
            print("Raw JSON: \(jsonMealEstimatesResult)")

            switch jsonMealEstimatesResult {
            case .success(let jsonMealEstimatesString):
                if let data = jsonMealEstimatesString.data(using: .utf8) {
                    do {

                        let decoded = try JSONDecoder().decode(MealEstimate.self, from: data)
                        result = decoded
                        showResult = true
                        print(decoded) //print the json received from chatgpt
                    } catch {
                        print("Decoding failed: \(error)")
                    }
                }
            case .failure(let error):
                print("API Error: \(error.localizedDescription)")
                    withAnimation {
                        errorMessage = "Meal upload failed. Please try again."
                        
                    }
            }
            userMeal = ""
            isLoading = false
        }
    }
}
