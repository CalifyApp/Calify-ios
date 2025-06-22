//
//  ContentView.swift
//  CalifyWatchApp Watch App
//
//  Created by christopher on 6/11/25.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    var body: some View {
        TabView {
            LogMealView()
            HistoryView()
            LoginView()
        }
        .tabViewStyle(.page)
        .onAppear {
            requestTokensFromiPhone()
        }
    }
}
func requestTokensFromiPhone() {
    let message = ["request": "authTokens"]
    print("📡 isReachable: \(WCSession.default.isReachable)")

    WCSession.default.sendMessage(message, replyHandler: { response in
        if let accessToken = response["accessToken"] as? String,
           let refreshToken = response["refreshToken"] as? String {
            print("✅ Access Token: \(accessToken)")
            print("✅ Refresh Token: \(refreshToken)")
            
            UserDefaults.standard.set(accessToken, forKey: "accessToken")
            UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
            print("Received tokens from iPhone.")
        }
        else {
                    print("❌ Missing tokens in response.")
                }

    }, errorHandler: { error in
        print("Failed to get tokens from iPhone: \(error)")
    })
}

#Preview {
    ContentView()
}
