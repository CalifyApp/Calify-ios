//
//  CheckMark.swift
//  mine
//
//  Created by justin lorenzo on 7/9/25.
//

import SwiftUI

struct CheckMarkView: View {
    let color: Color = .green
    let animate: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 5)
                .frame(width: 70, height: 70)

            Image(systemName: "checkmark")
                .foregroundColor(color)
                .font(.system(size: 35, weight: .bold))
                .scaleEffect(animate ? 1.2 : 0.6)
                .animation(.interpolatingSpring(stiffness: 200, damping: 10), value: animate)
        }
    }
}

#Preview {
    CheckMarkView(animate: true)
}
