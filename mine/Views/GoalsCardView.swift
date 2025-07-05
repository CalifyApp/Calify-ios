//
//  GoalsCardView.swift
//  mine
//
//  Created by christopher on 6/22/25.
//

import SwiftUI

struct GoalsCardView: View {
    
    @State private var isEditing = false
    @State private var calGoal: Int
    @State private var proteinGoal: Int
    @State private var carbGoal: Int
    @State private var fatGoal: Int

    @State private var tempCal = ""
    @State private var tempProtein = ""
    @State private var tempCarb = ""
    @State private var tempFat = ""

    @State private var isSaving = false
    @State private var errorMessage: String?

    let userId: String
    
    // Current values for progress calculation
    let currentCal: Int
    let currentProtein: Int
    let currentCarbs: Int
    let currentFat: Int

    init(userId: String, cal: Int, protein: Int, carbs: Int, fat: Int, currentCal: Int, currentProtein: Int, currentCarbs: Int, currentFat: Int) {
        self.userId = userId
        self._calGoal = State(initialValue: cal)
        self._proteinGoal = State(initialValue: protein)
        self._carbGoal = State(initialValue: carbs)
        self._fatGoal = State(initialValue: fat)
        self.currentCal = currentCal
        self.currentProtein = currentProtein
        self.currentCarbs = currentCarbs
        self.currentFat = currentFat
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    tempCal = String(calGoal)
                    tempProtein = String(proteinGoal)
                    tempCarb = String(carbGoal)
                    tempFat = String(fatGoal)
                    isEditing = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                CircularProgressGoal(
                    label: "Calories",
                    current: currentCal,
                    goal: calGoal,
                    color: .primary,
                    unit: "cal"
                )
                
                CircularProgressGoal(
                    label: "Protein",
                    current: currentProtein,
                    goal: proteinGoal,
                    color: .blue,
                    unit: "g"
                )
                
                CircularProgressGoal(
                    label: "Carbs",
                    current: currentCarbs,
                    goal: carbGoal,
                    color: .green,
                    unit: "g"
                )
                
                CircularProgressGoal(
                    label: "Fat",
                    current: currentFat,
                    goal: fatGoal,
                    color: .orange,
                    unit: "g"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $isEditing) {
            NavigationView {
                Form {
                    Section(header: Text("Daily Goals")) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Calories")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.orange)
                                                TextField("Enter calories", text: $tempCal)
                                                    .keyboardType(.numberPad)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Protein (g)")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.red)
                                                TextField("Enter protein in grams", text: $tempProtein)
                                                    .keyboardType(.numberPad)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Carbs (g)")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.green)
                                                TextField("Enter carbs in grams", text: $tempCarb)
                                                    .keyboardType(.numberPad)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Fat (g)")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.purple)
                                                TextField("Enter fat in grams", text: $tempFat)
                                                    .keyboardType(.numberPad)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                            }
                                        }
                    

                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }

                    if isSaving {
                        Section {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Saving...")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Update Goals")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveGoals()
                        }
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isEditing = false
                            errorMessage = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    func saveGoals() {
        guard let newCal = Int(tempCal),
              let newProtein = Int(tempProtein),
              let newCarb = Int(tempCarb),
              let newFat = Int(tempFat) else {
            errorMessage = "Please enter valid numbers for all fields."
            return
        }
        
        guard newCal > 0, newProtein > 0, newCarb > 0, newFat > 0 else {
            errorMessage = "All values must be greater than 0."
            return
        }

        isSaving = true
        errorMessage = nil

        Task {
            let success = await updateGoalsInSupabase(
                cal: newCal,
                protein: newProtein,
                carbs: newCarb,
                fat: newFat
            )
            
            await MainActor.run {
                isSaving = false
                if success {
                    calGoal = newCal
                    proteinGoal = newProtein
                    carbGoal = newCarb
                    fatGoal = newFat
                    isEditing = false
                } else {
                    errorMessage = "Failed to update goals. Please try again."
                }
            }
        }
    }

    func updateGoalsInSupabase(cal: Int, protein: Int, carbs: Int, fat: Int) async -> Bool {
        do {
            let result = try await SupabaseManager.shared.client
                .from("Profiles")
                .update([
                    "cal_goal": cal,
                    "protein_goal": protein,
                    "carb_goal": carbs,
                    "fat_goal": fat
                ])
                .eq("id", value: userId)
                .execute()

            return result.status == 200
        } catch {
            print("Supabase error: \(error)")
            return false
        }
    }
}

struct CircularProgressGoal: View {
    let label: String
    let current: Int
    let goal: Int
    let color: Color
    let unit: String
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }
    
    private var progressText: String {
        "\(current)/\(goal)"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)
                
                // Center text
                VStack(spacing: 0) {
                    Text("\(current)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    Text("\(unit)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Goal: \(goal) \(unit)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                
                // Progress percentage
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(progress >= 1.0 ? .green : color)
                    .opacity(0.8)
            }
        }
        .padding(.vertical, 8)
    }
}

//// Preview
//struct GoalsCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        GoalsCardView(
//            userId: "test-user",
//            cal: 2000,
//            protein: 150,
//            carbs: 250,
//            fat: 65,
//            currentCal: 1500,
//            currentProtein: 100,
//            currentCarbs: 180,
//            currentFat: 45
//        )
//        .padding()
//        .previewLayout(.sizeThatFits)
//    }
//}
