//
//  Permissions.swift
//  Calify
//
//  Created by justin lorenzo on 6/23/25.
//
import SwiftUI
import Speech

func permissions() async {
    await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization { status in
            print("Speech auth status: \(status)")
            continuation.resume()
        }
    }

    await withCheckedContinuation { continuation in
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print("Microphone access granted: \(granted)")
            continuation.resume()
        }
    }

}
