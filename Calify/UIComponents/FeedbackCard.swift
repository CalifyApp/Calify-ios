//
//  FeedbackCard.swift
//  mine
//
//  Created by justin lorenzo on 7/3/25.
//
import SwiftUI

struct FeedbackCard: View {
    let mealId: Int
    let accuracyFeedback: String?
    
    @State private var selected: FeedbackType? = nil

    enum FeedbackType {
        case thumbsUp, thumbsDown
    }
    
    init(mealId: Int, accuracyFeedback: String?) {
        self.mealId = mealId
        self.accuracyFeedback = accuracyFeedback
        
        if accuracyFeedback == "good" {
            _selected = State(initialValue: .thumbsUp)
        } else if accuracyFeedback == "bad" {
            _selected = State(initialValue: .thumbsDown)
        } else {
            _selected = State(initialValue: nil)
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 24) {
                Button(action: {
                    selected = .thumbsUp
                    Task {
                        await SupabaseManager.shared.updateMealFeedback(feedback: "good", mealId: mealId)
                        MealCacheManager.shared.updateFeedback(for: mealId, with: "good")
                    }
                }) {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(selected == .thumbsUp ? Color.green : Color.green.opacity(0.4))
                        .clipShape(Circle())
                        .scaleEffect(selected == .thumbsUp ? 1.15 : 1.0)
                        .shadow(color: selected == .thumbsUp ? Color.green.opacity(0.5) : .clear, radius: 6)
                        .animation(.easeInOut(duration: 0.2), value: selected)
                }

                Button(action: {
                    selected = .thumbsDown
                    Task {
                        await SupabaseManager.shared.updateMealFeedback(feedback: "bad", mealId: mealId)
                        MealCacheManager.shared.updateFeedback(for: mealId, with: "bad")
                    }
                }) {
                    Image(systemName: "hand.thumbsdown.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(selected == .thumbsDown ? Color.red : Color.red.opacity(0.4))
                        .clipShape(Circle())
                        .scaleEffect(selected == .thumbsDown ? 1.15 : 1.0)
                        .shadow(color: selected == .thumbsDown ? Color.red.opacity(0.5) : .clear, radius: 6)
                        .animation(.easeInOut(duration: 0.2), value: selected)
                }
            }
            
            Text("Was this meal accurate?")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}
