//
//  CalifyApp.swift
//  Calify
//
//  Created by christopher on 3/29/25.
//

import SwiftUI
import UserNotifications

@main //this is like the index.js or main file for the entire app. starting point.
struct CalifyApp: App {
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore: Bool = false
    @StateObject var streakManager = StreakManager()

    
    var body: some Scene { //think of body like return, it defines whats displayed
        WindowGroup { //represents window for the app, if this was macos, this owuld be a window. on ios, its main screen.
            if hasLaunchedBefore == true {
                ContentView()
            }
            else {
                SetupView()
            }
                
        }
        .environmentObject(streakManager)
    }
}

struct ContentView: View {
    @EnvironmentObject var streakManager: StreakManager

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
            print("🟢 ContentView appeared")
        }
        .overlay(
                    VStack {
                        if streakManager.showStreakBanner {
                            Text(streakManager.streakEmojiString)
                                .font(.title)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .padding(.top, 40)
                                .gesture(
                                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
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
