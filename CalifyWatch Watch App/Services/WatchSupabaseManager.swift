//
//  WatchSupabaseManager.swift
//  Calify
//
//  Created by christopher on 7/27/25.
//

import Foundation
import Supabase

class WatchSupabaseManager {
    static let shared = WatchSupabaseManager()

    let client: SupabaseClient

    private init() {
        let url = URL(string: "https://ypzdjlfgckfyqqhyhgjc.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwemRqbGZnY2tmeXFxaHloZ2pjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0NzM5MTYsImV4cCI6MjA1OTA0OTkxNn0.hv8kcWuQJsRXCswZFad2YAONTouzUat6rlwpU0CEX_s"

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }

    /// Call this right after receiving new tokens from iPhone
    func applySession(accessToken: String, refreshToken: String) async throws {
        do {
            try await client.auth.setSession(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
            print("Token session applied")
        } catch {
            print("failed to apply session: \(error)")
        }
    }
    func insertMeal(accessToken: String, description: String, calories: Int, protein: Int, carbs: Int, fat: Int, accuracyScore: Int, tips: [String]) async throws { //This will insert a new meal into the database.
        //TODO. Handle watch/iphone access token more gracefully.
            let user = try await client.auth.user(jwt: accessToken)
            print("Insert meal function shows userid", user.id)
        
            let meal = MealEstimate(
                id: nil, //auto generated, can be nil.
                user_id: user.id,
                protein: protein,
                carbs: carbs,
                fat: fat,
                calories: calories,
                description: description,
                accuracyScore: accuracyScore,
                accuracyFeedback: nil,
                created_at: nil,
                tips: tips
            )
            
            try await client.from("Meals").insert(meal).execute()
            print("insertion successful")
        
        
    }
}
