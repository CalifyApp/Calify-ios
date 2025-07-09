//
//  WatchSessionManager.swift
//  mine
//
//  Created by christopher on 6/15/25.
//

import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    
    override init() {
        super.init()
        print("WatchSessionManager init() called - about to activate session")
        activateSession()
        print("WatchSessionManager activateSession() completed")

    }
    
    //watch-iphone commnuication initalization session.
    public func activateSession() {
        print("activateSession() method called")
        if WCSession.isSupported() {
            print("WCSession is supported, setting up...")
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("WCSession.activate() called")
        } else {
            print("WCSession is NOT supported")
        }
    }
    func sendAuthTokenToWatch(accessToken: String, refreshToken: String) {
        
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }
        let message = [
            "accessToken": accessToken,
            "refreshToken": refreshToken
        ]
        WCSession.default.sendMessage(message, replyHandler: nil) {
            error in print("error sending message to watch: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Required for iOS
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iPhone WCSession activation completed with state: \(activationState.rawValue)")
        if let error = error {
            print("iPhone WCSession activation error: \(error)")
        }
        
        // Now check the session state after activation completes
        print("=== POST-ACTIVATION DEBUG ===")
        print("WCSession paired: \(WCSession.default.isPaired)")
        print("WCSession installed: \(WCSession.default.isWatchAppInstalled)")
        print("WCSession reachable: \(WCSession.default.isReachable)")
        print("WCSession state: \(WCSession.default.activationState.rawValue)")
        print("=============================")
    }
    
    // MARK: - Handle messages from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["request"] as? String == "authTokens" {
            let accessToken = UserDefaults.standard.string(forKey: "accessToken") ?? ""
            let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") ?? ""
            
            replyHandler([
                "accessToken": accessToken,
                "refreshToken": refreshToken
            ])
        }
    }
    
}
