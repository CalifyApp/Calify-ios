//
//  FailureMarkView.swift
//  Calify
//
//  Created by justin lorenzo on 7/30/25.
//

import SwiftUI

struct FailureMarkView: View {
    let color: Color = .red
    let animate: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 5)
                .frame(width: 70, height: 70)

            Image(systemName: "xmark")
                .foregroundColor(color)
                .font(.system(size: 35, weight: .bold))
                .scaleEffect(animate ? 1.2 : 0.6)
                .animation(.interpolatingSpring(stiffness: 200, damping: 10), value: animate)
        }
    }
}

#Preview {
    FailureMarkView(animate: true)
}
