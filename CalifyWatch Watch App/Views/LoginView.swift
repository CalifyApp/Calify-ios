//
//  LoginView.swift
//  mine
//
//  Created by christopher on 6/20/25.
//
import SwiftUI

struct LoginView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared

    var body: some View {
        VStack(spacing: 16) {
            // Show connection status
            HStack {
                Circle()
                    .fill(sessionManager.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(sessionManager.connectionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Action buttons
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
