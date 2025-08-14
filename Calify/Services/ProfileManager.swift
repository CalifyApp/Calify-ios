//
//  ProfileManager.swift
//  Calify
//
//  Created by claude on 8/12/25.
//

import Foundation

@MainActor
class ProfileManager: ObservableObject {
    
    @Published var profile: Profiles? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadProfile() async {
        guard profile == nil else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await SupabaseManager.shared.getProfilesInfo()
            if let loadedProfile = result {
                profile = loadedProfile
            } else {
                errorMessage = "Profile not found"
            }
        } catch {
            errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateGoals(cal: Int, protein: Int, carbs: Int, fat: Int) async -> Bool {
        guard let currentProfile = profile,
              let userId = currentProfile.id else {
            errorMessage = "No profile loaded"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await SupabaseManager.shared.client
                .from("Profiles")
                .update([
                    "cal_goal": cal,
                    "protein_goal": protein,
                    "carb_goal": carbs,
                    "fat_goal": fat
                ])
                .eq("id", value: userId.uuidString)
                .execute()
            
            if result.status == 200 {
                profile = Profiles(
                    id: currentProfile.id,
                    created_at: currentProfile.created_at,
                    name: currentProfile.name,
                    cal_goal: cal,
                    protein_goal: protein,
                    fat_goal: fat,
                    carb_goal: carbs
                )
                isLoading = false
                return true
            } else {
                errorMessage = "Failed to update goals"
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Error updating goals: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func refresh() async {
        profile = nil
        await loadProfile()
    }
}
