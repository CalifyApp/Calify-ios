import SwiftUI
import Combine

struct WaterView: View {
    
    @EnvironmentObject var waterManager: WaterManager
    @State private var customAmount: String = ""
    @State private var confirmationMessage: String? = nil
    @State private var maxIntakeReached: Bool = false
    @State private var checkmarkBounce = false
    @State private var midnightTimer: Timer?
    
    @State private var keyboardHeight: CGFloat = 0

    private let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    private let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    
    private let maxIntake = 1000

    var body: some View {
        
        ZStack {
            Color.black.opacity(0.01)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { hideKeyboard() }

            VStack {
                
                TimelineBar(waterManager: waterManager)
                               .padding(.horizontal, 32)
                
                Spacer().frame(height: 40)
                

                WaterGaugeView(currentIntake: min(waterManager.totalToday, maxIntake))
                    .environmentObject(waterManager)

                HStack(spacing: 15) {
                    ForEach([8, 16, 24], id: \.self) { amount in
                        Button(action: {
                            let newTotal = min(waterManager.totalToday + amount, maxIntake)
                            let added = newTotal - waterManager.totalToday
                            waterManager.add(amount: added)

                            if added <= 0 {
                                maxIntakeReached = true
                                hideKeyboard()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { maxIntakeReached = false }
                                }
                            }
                            else {
                                showConfirmation("\(added) oz added!")
                                withAnimation { checkmarkBounce = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { checkmarkBounce = false }
                                }
                            }
//                            waterManager.entries.removeAll()

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
                
                ZStack{
                    Text(confirmationMessage ?? "")
                        .font(.footnote)
                        .foregroundColor(.green)
                        .frame(height: 20)
                        .opacity(confirmationMessage == nil ? 0 : 1)
                        .padding(.top, 16)
                        .animation(.easeInOut(duration: 0.3), value: confirmationMessage)
                    
                    if (maxIntakeReached) {
                        Text("Max daily water reached!")
                            .font(.footnote)
                            .foregroundColor(.green)
                            .frame(height: 20)
                            .opacity(maxIntakeReached == false ? 0 : 1)
                            .padding(.top, 16)
                            .animation(.easeInOut(duration: 0.3), value: "Max daily water reached!")
                    }
                }
//                .frame(height: 10)
                .offset(y: keyboardHeight > 0 ? -25 : 0)
                .animation(.easeOut(duration: 0.3), value: keyboardHeight)

                ZStack {
                    CheckMarkView(animate: checkmarkBounce)
                        .opacity(checkmarkBounce ? 1 : 0)
                }
                .frame(height: 120)
                .offset(y: keyboardHeight > 0 ? -25 : 0)
                .animation(.easeOut(duration: 0.3), value: keyboardHeight)

                VStack {
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
                                let newTotal = min(waterManager.totalToday + value, maxIntake)
                                let added = newTotal - waterManager.totalToday
                                waterManager.add(amount: added)
                                if added <= 0 {
                                    maxIntakeReached = true
                                    hideKeyboard()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { maxIntakeReached = false }
                                    }
                                }
                                else {
                                    showConfirmation("\(added) oz added!")
                                    customAmount = ""
                                    hideKeyboard()
                                    withAnimation { checkmarkBounce = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { checkmarkBounce = false }
                                    }
                                }
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
                }
                .offset(y: keyboardHeight > 0 ? -50 : 0)
                .animation(.easeOut(duration: 0.3), value: keyboardHeight)

                Spacer()
            }
        }
        .gradientBackground()
        .onAppear {
            waterManager.scheduleMidnightReset()
        }
        .onReceive(keyboardWillShow) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation {
                    keyboardHeight = keyboardFrame.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
                }
            }
        }
        .onReceive(keyboardWillHide) { _ in
            withAnimation { keyboardHeight = 0 }
        }
    }
    
    func showConfirmation(_ message: String) {
        confirmationMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { confirmationMessage = nil }
        }
    }

//    func scheduleMidnightReset() {
//        midnightTimer?.invalidate()
//        
//        let calendar = Calendar.current
//        let now = Date()
//        let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime)!
//        let interval = nextMidnight.timeIntervalSince(now)
//        
//        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
//            currentIntake = 0
//            WaterTrackerStorage.save(intake: 0)
//            scheduleMidnightReset()
//        }
//    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
