////
////  ProfileView.swift
////  Calify
////
////  Created by christopher on 3/29/25.
////
///
import SwiftUI
import MessageUI

enum ProfileChild: Hashable {
    case nutrientGoals
    case none
}

struct ProfileView: View {
    @Binding var goToChild: ProfileChild
    @State private var navigationCards: [NavigationCardData] = [
        NavigationCardData(id: UUID(), title: "Support Email"),
        NavigationCardData(id: UUID(), title: "Nutrient Goals"),
        NavigationCardData(id: UUID(), title: "Feedback Form")
    ]
    @State private var showingMailComposer = false
    @State private var userId: String = "Loading..."
    @State private var path: [ProfileChild] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(navigationCards) { card in
                        if card.title == "Support Email" {
                            Button(action: {
                                showingMailComposer = true
                            }) {
                                NavigationCardView(title: card.title)
                            }
                            .buttonStyle(.plain)
                        } else if card.title == "Feedback Form" {
                            Button(action: {
                                if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSf-GZjCJH9xsdeZajO_Mz-NqtdF5wdpYY8oU8K8zbT1q0gntA/viewform?usp=header") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                NavigationCardView(title: card.title, isExternalLink: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                goToChild = .nutrientGoals
                            } label: {
                                NavigationCardView(title: card.title)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .gradientBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task { await loadUserId() }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(
                    recipients: ["chrisnieves60@gmail.com"],
                    subject: "Calify App Support"
                )
            }
            .navigationDestination(for: ProfileChild.self) { child in
                switch child {
                case .nutrientGoals:
                    GoalsView()
                default:
                    EmptyView()
                }
            }
        }
        .onChange(of: goToChild) { newValue in
            if newValue == .nutrientGoals {
                path.removeAll()
                path.append(.nutrientGoals)     
                goToChild = .none
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
    let isExternalLink: Bool
    
    init(title: String, destination: AnyView? = nil, isExternalLink: Bool = false) {
        self.title = title
        self.destination = destination
        self.isExternalLink = isExternalLink
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
            
            Image(systemName: isExternalLink ? "arrow.up.right.square" : "chevron.right")
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
