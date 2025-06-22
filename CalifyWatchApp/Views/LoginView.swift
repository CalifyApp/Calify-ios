//
//  LoginView.swift
//  mine
//
//  Created by christopher on 6/20/25.
//
import SwiftUI

struct LoginView: View {
    var body: some View {
        if let user = SupabaseManager.shared.client.auth.currentUser {
            Text("✅ Logged in as user ID: \(user.id)")
        } else {
            Text("❌ Not logged in — no current user.")
        }
    }
}
