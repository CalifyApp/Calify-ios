//
//  HistoryView.swift
//  mine
//
//  Created by christopher on 6/12/25.
//
import SwiftUI

struct HistoryView: View {
    var body: some View {
        Button("Request Tokens") {
                        requestTokensFromiPhone()
                    }
        //TODO: CURRENTLY HELPER FUNCTION TO ENSURE SHARED AUTH SESSION.
        Button("Set session") {
            Task {

                do {
                    try await SupabaseManager.shared.client.auth.setSession(
                        accessToken: UserDefaults.standard.string(forKey: "accessToken") ?? "",
                        refreshToken: UserDefaults.standard.string(forKey: "refreshToken") ?? ""
                    )
                    if let user = SupabaseManager.shared.client.auth.currentUser {
                        print("✅ Logged in as user ID: \(user.id)")
                    } else {
                        print("❌ Not logged in — no current user.")
                    }
                } catch {
                    print("Failed to set session")
                }
            }
        }


    }
}

