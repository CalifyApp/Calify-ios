//
//  Untitled.swift
//  Calify
//
//  Created by christopher on 6/21/25.
//

//listens for when keyboard shows or hides, tell view how tall keyboard is.
import SwiftUI
import Combine

class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    private var cancellable: AnyCancellable?

    init() {
        cancellable = Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .handleEvents(receiveOutput: { _ in print("⚠️ Keyboard will show") })
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
                .map { rect in
                    print("🧠 Keyboard height: \(rect.height)")
                    return rect.height
                },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .handleEvents(receiveOutput: { _ in print("👋 Keyboard will hide") })
                .map { _ in CGFloat(0) }
        )
        .receive(on: RunLoop.main)
        .assign(to: \.currentHeight, on: self)
    }
}
