//
//  GradientBackground.swift
//  Calify
//
//  Created by justin lorenzo on 8/4/25.
//

import SwiftUI

struct GradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#4A90E2"), Color(hex: "#50E3C2")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            content
        }
    }
}

extension View {
    func gradientBackground() -> some View {
        self.modifier(GradientBackground())
    }
}
