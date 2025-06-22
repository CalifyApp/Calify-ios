//
//  NameSetupView.swift
//  mine
//
//  Created by christopher on 5/18/25.
//

import Foundation
import SwiftUI

struct NameSetupView: View {
    @State private var name: String = ""
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore: Bool = false
    @AppStorage("userName") var userName: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome!")
                .font(.largeTitle)

            TextField("Please enter your name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Continue") {
                userName = name
                hasLaunchedBefore = true
                Task {
                    do {
                        var userID: UUID?
                        if let session = try? await SupabaseManager.shared.client.auth.session {
                            userID = session.user.id
                            print("Existing session: \(userID!)")
                        }
                        if userID == nil {
                            if let newSession = try? await SupabaseManager.shared.client.auth.signInAnonymously() {
                                userID = newSession.user.id
                                print("Signed in anonymously: \(userID!)")
                            }
                        }
                        guard let finalUserID = userID else {
                            print("Failed to get a user ID")
                            return
                        }
                        
                        let userProfile = Profiles(
                            id: finalUserID,
                            created_at: nil,
                            name: name
                        )
                        try await SupabaseManager.shared.client.from("Profiles").insert(userProfile).execute()
                    }
                    catch {
                        print("Error inserting profile: ", error)
                    }
                }
            }
            
        }
        .padding()
    }
}


