//
//  ContentView.swift
//  CalifyWatch Watch App
//
//  Created by christopher on 7/14/25.
//
//
//  ContentView.swift
//  CalifyWatchApp Watch App
//
//  Created by christopher on 6/11/25.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @State private var sessionValid: Bool = true

    var body: some View {
        TabView {
            LogMealView()
            LoginView()
        }
        .tabViewStyle(.page)
        .overlay (
            Group {
                    if !sessionValid {
                        Color.black.opacity(0.85)
                            .ignoresSafeArea()
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Session expired.\nOpen Calify on your iPhone to continue.")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white)
                                        .font(.footnote)
                                    Text("Tap to retry")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .onTapGesture {
                                Task {
                                    sessionManager.requestTokensFromiPhone()
                                    sessionValid = await isSessionValid()
                                }
                            }
                    }
                }

        )
        .onAppear {
            sessionManager.requestTokensFromiPhone() //on content view appear.
            Task {
                    do {
                        let accessToken = UserDefaults.standard.string(forKey: "accessToken") ?? ""
                        let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") ?? ""
                        try await WatchSupabaseManager.shared.client.auth.setSession(
                            accessToken: accessToken,
                            refreshToken: refreshToken
                        )
                        // ✅ Now validate the session
                        sessionValid = await isSessionValid()

                    } catch {
                        print("Failed to set Supabase session:", error)
                        sessionValid = false
                    }
                }

        }
        
    }
}

func isSessionValid() async -> Bool {
    do {
        _ = try await WatchSupabaseManager.shared.client.auth.session.user
        return true
    } catch {
        // Print the error if you want to debug
        print("❌ Session invalid: \(error)")
        return false
    }
}

#Preview {
    ContentView()
}
