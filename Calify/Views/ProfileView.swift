////
////  ProfileView.swift
////  Calify
////
////  Created by christopher on 3/29/25.
////
///
import SwiftUI
import MessageUI

struct ProfileView: View {
    @State private var navigationCards: [NavigationCardData] = [
        NavigationCardData(id: UUID(), title: "Support Email"),
        NavigationCardData(id: UUID(), title: "Nutrient Goals")
    ]
    @State private var showingMailComposer = false
    @State private var userId: String = "Loading..."
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                // Personal Details Card (always at top)
//                VStack(alignment: .leading, spacing: 0) {
//                    Text("Personal Details")
//                        .font(.title2)
//                        .fontWeight(.semibold)
//                        .padding(.horizontal, 20)
//                        .padding(.top, 20)
//                        .padding(.bottom, 16)
//                    
//                    // Stats Grid
//                    HStack(spacing: 0) {
//                        // Left Column
//                        VStack(spacing: 20) {
//                            StatItemView(
//                                icon: "ruler",
//                                iconColor: .blue,
//                                title: "Height",
//                                value: "5'10\""
//                            )
//                            
//                            StatItemView(
//                                icon: "calendar",
//                                iconColor: .orange,
//                                title: "Age",
//                                value: "28"
//                            )
//                        }
//                        .frame(maxWidth: .infinity)
//                        
//                        // Right Column
//                        VStack(spacing: 20) {
//                            StatItemView(
//                                icon: "scalemass",
//                                iconColor: .green,
//                                title: "Weight",
//                                value: "170 lbs"
//                            )
//                            
//                            StatItemView(
//                                icon: "person",
//                                iconColor: .purple,
//                                title: "Gender",
//                                value: "Male"
//                            )
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 20)
//                }
//                .background(Color.white)
//                .cornerRadius(16)
//                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Dynamic Navigation Cards
                ForEach(navigationCards) { card in
                    if card.title == "Support Email" {
                        Button(action: {
                            showingMailComposer = true
                        }) {
                            NavigationCardView(title: card.title)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        NavigationCardView(title: card.title, destination: card.title == "Nutrient Goals" ? AnyView(GoalsView()) : nil)
                    }
                }
            }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                
            } .gradientBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await loadUserId()
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(
                    recipients: ["chrisnieves60@gmail.com"],
                    subject: "Calify App Support"
                )
            }
        }
    }
    
    private func loadUserId() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            userId = session.user.id.uuidString
        } catch {
            userId = "Unable to retrieve user ID"
        }
    }
    
    private func getEmailBody() -> String {
        return """


Please describe your issue above this line.

User ID: \(userId)
"""
    }
    
}

struct NavigationCardData: Identifiable {
    let id: UUID
    let title: String
}

struct StatItemView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
    }
}

struct NavigationCardView: View {
    let title: String
    let destination: AnyView?
    
    init(title: String, destination: AnyView? = nil) {
        self.title = title
        self.destination = destination
    }
    
    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    @State private var userId: String = "Loading..."
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients(recipients)
        mailComposer.setSubject(subject)
        
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userIdValue = session.user.id.uuidString
                let body = """


Please describe your issue above this line.

User ID: \(userIdValue)
"""
                await MainActor.run {
                    mailComposer.setMessageBody(body, isHTML: false)
                }
            } catch {
                let body = """


Please describe your issue above this line.

User ID: Unable to retrieve user ID
"""
                await MainActor.run {
                    mailComposer.setMessageBody(body, isHTML: false)
                }
            }
        }
        
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

//
//import SwiftUI
//
//struct ProfileView: View {
//    @State private var profile: Profiles? = nil
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Welcome! You are currently signed in as a guest. Login feature coming soon...")
//            if let profile = profile {
//                GoalsCardView(
//                    userId: profile.id?.uuidString ?? "unknown",
//                    cal: profile.cal_goal ?? 2000,
//                    protein: profile.protein_goal ?? 50,
//                    carbs: profile.carb_goal ?? 250,
//                    fat: profile.fat_goal ?? 70
//                )
//            } else{
//                ProgressView("Loading...")
//            }
//            
//        }
//        .padding()
//        .gradientBackground()
//        .task {
//            print("🌀 .task started in ProfileView")
//
//                if profile == nil {
//                    do {
//                        let result = try await SupabaseManager.shared.getProfilesInfo()
//                        print("result")
//                        if let loadedProfile = result {
//                            print("✅ Profile loaded: \(loadedProfile)")
//                            profile = loadedProfile
//                        } else {
//                            print("⚠️ Supabase returned nil profile")
//                        }
//                    } catch {
//                        print("❌ Failed to fetch profile: \(error)")
//                    }
//                } else {
//                    print("ℹ️ Profile already loaded")
//                }
//            }
//
//        }
//    }
//
