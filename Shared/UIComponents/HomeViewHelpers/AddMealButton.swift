//
//  AddMealButton.swift
//  Calify
//
//  Created by justin lorenzo on 8/4/25.
//

import SwiftUI

struct AddMealButton: View {
    var action: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding(.bottom, 10) // Adjust this so it sits above the TabView
            .padding(.trailing, 20)
        }
    }
}
