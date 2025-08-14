//
//  CalifyApp.swift
//  Calify
//
//  Created by christopher on 3/29/25.
//

import SwiftUI
import WatchConnectivity
import UserNotifications

@main //this is like the index.js or main file for the entire app. starting point.
struct CalifyApp: App {
    init() {
        _ = WatchSessionManager.shared  // ensures WCSession is activated
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore: Bool = false
    @AppStorage("userName") var userName: String = ""
    @StateObject var streakManager = StreakManager()
    @StateObject var waterManager = WaterManager()
    @StateObject private var nutritionManager = DailyNutritionManager()
    
    
    var body: some Scene { //think of body like return, it defines whats displayed
        
        
        WindowGroup { //represents window for the app, if this was macos, this would be a window. on ios, its main screen.
            ContentView()
        }
        .environmentObject(streakManager)
        .environmentObject(nutritionManager)
        .environmentObject(waterManager)
    }
}

struct ContentView: View {
    @State private var todaysTotal: NutrientTotals? = nil
    @State private var selectedTab = 0
    @EnvironmentObject var streakManager: StreakManager

    var body: some View {
        TabView (selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

//            TodayView()
//                .tabItem {
//                    Image(systemName: "clock.fill")
//                    Text("History")
//                }
            WaterView()
                .tabItem{
                    Image(systemName: "drop.fill")
                    Text("Water Intake")
                }
                .tag(1)

            ProfileView()
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(2)
        }
        .onAppear {
            Task {
                await sendTokensToWatch()
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
                            let userProfile = Profiles(
                                id: userID,
                                created_at: nil,
                                name: nil,
                                cal_goal: nil,
                                protein_goal: nil,
                                fat_goal: nil,
                                carb_goal: nil
                            )
                            try await SupabaseManager.shared.client.from("Profiles").insert(userProfile).execute()
                        }
                    }
                    guard let finalUserID = userID else {
                        print("Failed to get a user ID")
                        return
                    }
                    
                }
            }
        }
        .overlay(
            VStack {
                if streakManager.showStreakBanner {
                    StreakBannerView(currentStreak: streakManager.currentStreak)
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onEnded { value in
                                    if value.translation.height < -10 {
                                        withAnimation {
                                            streakManager.showStreakBanner = false
                                        }
                                    }
                                }
                        )
                }
                Spacer()
            }
            .animation(.easeInOut, value: streakManager.showStreakBanner)
        )
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
