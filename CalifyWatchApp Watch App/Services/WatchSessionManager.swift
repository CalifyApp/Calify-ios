//
//  WatchSessionManager.swift
//  mine
//
//  Created by christopher on 6/17/25.
//

import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    override init() {
        super.init()
        activateSession()
    }
    
    func activateSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // Required for watchOS WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch WCSession activated with state: \(activationState.rawValue)")
        if let error = error {
            print("Watch WCSession activation error: \(error)")
        }
    }

    // Handle messages from iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Watch received message: \(message)")
        
        if message["request"] as? String == "authTokens" {
            print("Watch handling authTokens request")
            // This is probably what your iPhone app is expecting
            replyHandler([
                "accessToken": "some-token",
                "refreshToken": "some-refresh-token"
            ])
        } else {
            // Default reply for other messages
            replyHandler(["status": "received"])
        }
    }

}
