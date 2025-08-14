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
    @Environment(\.scenePhase) var scenePhase
    @StateObject var waterManager = WaterManager()
    @StateObject private var nutritionManager = DailyNutritionManager()
    @StateObject private var profileManager = ProfileManager()

    
    var body: some Scene {
        
        
        
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) {
                    //I think that autorefresh supabase is doing its job, BUT, I am going to keep this code here, that refetches tokens, just in case...
                    if scenePhase == .active {
                        Task {
                            do {
                                //see if jwt is valid.

                                print("lets see if our token is still valid. Checking session...")
                                _ = try await SupabaseManager.shared.client.auth.user() //if jwt is invalid, itll jump to the catch block. TODO: Test this.
                                print("if we make it here, our tokens still valid, lets reset all tokens anyways. and store in user defaults.")
                                let session = try await SupabaseManager.shared.client.auth.session
                                let accessToken = session.accessToken
                                let refreshToken = session.refreshToken
                                print("session: ", session)
                                //Save to userdefaults for watch to read
                                UserDefaults.standard.set(accessToken, forKey: "accessToken")
                                UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                                print("Token still valid, restored tokens in userDefaults ")
                                
                                        
                            } catch {
                                //JWT wasnt valid, or other issue with getting cur session.
                                do {
                                        print("our tokens were NOT valid... lets try refreshing the session. ")
                                        try await SupabaseManager.shared.client.auth.refreshSession()

                                        let session = try await SupabaseManager.shared.client.auth.session
                                        let accessToken = session.accessToken
                                        let refreshToken = session.refreshToken

                                        UserDefaults.standard.set(accessToken, forKey: "accessToken")
                                        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                                        print("session refresh successful! Successfully stored new access tokens bc of invalid session.")
                                    } catch {
                                        print("❌ Failed to refresh session. Critical Error: \(error)")
                                    }
                            }
                        }
                    }
                }
        }
        .environmentObject(streakManager)
        .environmentObject(nutritionManager)
        .environmentObject(profileManager)
        .environmentObject(waterManager)
    }
}

struct ContentView: View {
    @State private var todaysTotal: NutrientTotals? = nil
    @EnvironmentObject var streakManager: StreakManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            GraphView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Progress")
                }

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

            ProfileView()
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
        }
        .onAppear {
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
                    await sendTokensToWatch()

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
