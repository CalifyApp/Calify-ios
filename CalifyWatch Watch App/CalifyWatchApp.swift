//
//  CalifyWatchApp.swift
//  CalifyWatch Watch App
//
//  Created by christopher on 7/14/25.
//

//
//  CalifyWatchAppApp.swift
//  CalifyWatchApp Watch App
//
//  Created by christopher on 6/11/25.
//

import SwiftUI
import Supabase
import Foundation
import WatchConnectivity

@main
struct CalifyWatchApp: App {
    init() {
        //Activate Watch Connectivity early
        _ = WatchSessionManager.shared
        print("WCSession supported: \(WCSession.isSupported())")
        print("WCSession reachable: \(WCSession.default.isReachable)")
        print("WCSession state: \(WCSession.default.activationState.rawValue)")
        
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

