//
//  CalifyApp.swift
//  Calify
//
//  Created by christopher on 3/29/25.
//

import SwiftUI

@main //this is like the index.js or main file for the entire app. starting point.
struct CalifyApp: App {
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore: Bool = false

    var body: some Scene { //think of body like return, it defines whats displayed
        WindowGroup { //represents window for the app, if this was macos, this owuld be a window. on ios, its main screen.
            if hasLaunchedBefore == true {
                ContentView()
            }
            else {
                NameSetupView()
            }
                
        }
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
            print("🟢 ContentView appeared")
        }
    }
}
