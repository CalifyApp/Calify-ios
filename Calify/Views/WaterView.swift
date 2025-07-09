import SwiftUI

struct WaterView: View {
    @State private var customAmount: String = ""
    @State private var confirmationMessage: String? = nil
    @State private var currentIntake: Int = WaterTrackerStorage.loadIntake()
    @State private var midnightTimer: Timer?
    
    

    var body: some View {
        VStack {
            Spacer().frame(height: 85)

            WaterGaugeView(currentIntake: currentIntake)

            HStack(spacing: 15) {
                ForEach([8, 16, 24], id: \.self) { amount in
                    Button(action: {
                        currentIntake = currentIntake + amount
                        WaterTrackerStorage.save(intake: currentIntake)
                        showConfirmation("\(amount) oz added!")
                    }) {
                        Text("+\(amount)oz")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 34)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                }
            }


            Text(confirmationMessage ?? "")
                .font(.footnote)
                .foregroundColor(.green)
                .frame(height: 20)
                .opacity(confirmationMessage == nil ? 0 : 1)
                .padding(.top, 16)
                .animation(.easeInOut(duration: 0.3), value: confirmationMessage)
            
            HStack(spacing: 12) {
                TextField("Enter oz", text: $customAmount)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                    .frame(width: 120)

                Button(action: {
                    if let value = Int(customAmount), value > 0 {
                        currentIntake = currentIntake + value
                        WaterTrackerStorage.save(intake: currentIntake)
                        showConfirmation("\(value) oz added!")
                        customAmount = ""
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
            }
            .padding(.top, 100)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            scheduleMidnightReset()
        }
    }
    
    func showConfirmation(_ message: String) {
        confirmationMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                confirmationMessage = nil
            }
        }
    }
    
    func scheduleMidnightReset() {
    
        midnightTimer?.invalidate()
        
        let calendar = Calendar.current
        let now = Date()
        let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime)!
        let interval = nextMidnight.timeIntervalSince(now)
        
        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            currentIntake = 0
            WaterTrackerStorage.save(intake: 0)
            scheduleMidnightReset()
        }
    }
}

#Preview {
    WaterView()
}
