//
//  LogMealView.swift
//  mine
//
//  Created by christopher on 6/12/25.
//
import SwiftUI

struct LogMealView: View {
    @State private var userMeal: String = ""
    @State private var isLoading = false
    @State private var toggleRecord = false
    @State private var result: MealEstimate? = nil
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20){
            Text("Log your meal")
                .font(.headline)
            
            TextField("Describe your meal...", text: $userMeal)
            Button {
                submitMeal()
                

            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding(.trailing)
            .disabled(userMeal.isEmpty)
        }
        .padding()
    }
    
    
    
    //TODO: CODE REFACTOR NEEDED!! THIS FUNCTION EXISTS IN HOMEVIEW.
    private func submitMeal() {
        guard !userMeal.isEmpty else { return }
        
        isLoading = true
        
        
        Task {
            let jsonMealEstimatesResult = await SupabaseManager.shared.callOpenAI(meal: userMeal) //actual meal estimates
            
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
                print("API Error: \(error)")
                
            }
            userMeal = ""
            isLoading = false
            await SupabaseManager.shared.insertMeal(
                description: result?.description ?? "",
                calories: result?.calories ?? 0,
                protein: result?.protein ?? 0,
                carbs: result?.carbs ?? 0,
                fat: result?.fat ?? 0,
                accuracyScore: result?.accuracyScore ?? 0,
                tips: result?.tips ?? [""]
                )
        }
    }
}
