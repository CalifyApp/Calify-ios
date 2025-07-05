//
//  CalifyApp.swift
//  Calify
//
//  Created by christopher on 3/29/25.
//

import SwiftUI
import WatchConnectivity
@main //this is like the index.js or main file for the entire app. starting point.
struct CalifyApp: App {
    init() {
            _ = WatchSessionManager.shared  // ensures WCSession is activated
    }

    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore: Bool = false
    @StateObject private var nutritionManager = DailyNutritionManager()

    var body: some Scene { //think of body like return, it defines whats displayed
        
        WindowGroup { //represents window for the app, if this was macos, this would be a window. on ios, its main screen.
            if hasLaunchedBefore == true {
                ContentView()
            }
            else {
                NameSetupView()
            }
        }
        .environmentObject(nutritionManager)
    }
}

struct ContentView: View {

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            TodayView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            WaterView()
                .tabItem{
                    Image(systemName: "drop.fill")
                    Text("Water Intake")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .onAppear {
            Task {
                await sendTokensToWatch()
            }
        }
    }
}

func sendTokensToWatch() async {
    do {
            let session = try await SupabaseManager.shared.client.auth.session
            let accessToken = session.accessToken
            let refreshToken = session.refreshToken
            
            //Save to userdefaults for watch to read
            UserDefaults.standard.set(accessToken, forKey: "accessToken")
            UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
            
            WatchSessionManager.shared.sendAuthTokenToWatch(accessToken: accessToken, refreshToken: refreshToken)
            print("Tokens fetched and sent")
    } catch {
        print("Failed to fetch session \(error)")
    }
}
