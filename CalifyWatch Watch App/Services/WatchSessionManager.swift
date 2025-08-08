//
//  WatchSessionManager.swift
//  CalifyWatch Watch App
//
//  Created by christopher on 7/14/25.
//

import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    var onTokensUpdated: (() -> Void)? = nil
    
    @Published var isConnected = false
    @Published var connectionStatus = "Initializing..."
    @Published var hasTokens = false
    
    override init() {
        super.init()
        print("Watch WatchSessionManager init() called - about to activate session")
        activateSession()
        print("Watch WatchSessionManager activateSession() completed")
    }
    
    public func activateSession() {
        print("Watch activateSession() method called")
        if WCSession.isSupported() {
            print("Watch WCSession is supported, setting up...")
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("Watch WCSession.activate() called")
        } else {
            print("Watch WCSession is NOT supported")
        }
    }
    
    // MARK: - WCSessionDelegate (Required for watchOS)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch WCSession activation completed with state: \(activationState.rawValue)")
        
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            self.connectionStatus = activationState == .activated ? "Ready" : "Failed to activate"
        }
        
        if let error = error {
            print("Watch WCSession activation error: \(error)")
            DispatchQueue.main.async {
                self.connectionStatus = "Activation error"
            }
        }
        
        // Debug info like your iPhone version
        print("=== WATCH POST-ACTIVATION DEBUG ===")
        print("WCSession reachable: \(WCSession.default.isReachable)")
        print("WCSession state: \(WCSession.default.activationState.rawValue)")
        print("===================================")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch session reachability changed: \(session.isReachable)")
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            self.connectionStatus = session.isReachable ? "Connected" : "iPhone not reachable"
        }
    }
    
    // MARK: - Token Requests (Watch sends requests to iPhone)
    func requestTokensFromiPhone() {
        print("📡 Requesting tokens from iPhone...")
        print("📡 isReachable: \(WCSession.default.isReachable)")
        
        guard WCSession.default.isReachable else {
            print("❌ iPhone not reachable")
            DispatchQueue.main.async {
                self.connectionStatus = "iPhone not reachable"
                self.hasTokens = false
            }
            return
        }
        
        let message = ["request": "authTokens"]
        
        DispatchQueue.main.async {
            self.connectionStatus = "Requesting tokens..."
        }
        
        WCSession.default.sendMessage(message, replyHandler: { response in
            print("✅ Received response from iPhone: \(response)")
            if let accessToken = response["accessToken"] as? String,
               let refreshToken = response["refreshToken"] as? String {
                //print tokens from the response from iphone.
                print("✅ Access Token from iphone res: \(accessToken)")
                print("✅ Refresh Token from iphone res:: \(refreshToken)")
                
                //why are we setting the tokens after printing
                UserDefaults.standard.set(accessToken, forKey: "accessToken")
                UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                Task {
                    do {
                        try await WatchSupabaseManager.shared.client.auth.setSession(
                            accessToken: accessToken,
                            refreshToken: refreshToken
                        )
                        print("✅ New session set on Watch")

                        // Notify SwiftUI view to re-check session validity
                        await MainActor.run {
                            self.onTokensUpdated?()
                        }
                    } catch {
                        print("❌ Failed to apply new session: \(error)")
                    }
                }
            

                //cuz we set locally... okay..
                //lets print tokens from the set...
                print("Token from watch localstorage", UserDefaults.standard.string(forKey: "accessToken") ?? "")
            }

        }, errorHandler: { error in
            print("❌ Failed to get tokens from iPhone: \(error)")
            DispatchQueue.main.async {
                self.connectionStatus = "Request failed"
                self.hasTokens = false
            }
        })
    }
}
