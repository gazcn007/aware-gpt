//
//  ContentView.swift
//  AwareGPT
//
//  Created by Carl Liu on 2025-12-07.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var selectedConversation: Conversation?
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var llmService: LLMService
  @Query(sort: \Conversation.createdAt) private var conversations: [Conversation]
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var showOnboarding = false

  var body: some View {
    NavigationSplitView {
      if conversations.isEmpty {
        // Empty state with Get Started button
        VStack(spacing: 24) {
          Spacer()

          VStack(spacing: 16) {
            Image(systemName: "sparkles")
              .font(.system(size: 60))
              .foregroundStyle(
                LinearGradient(
                  colors: [.accentColor, .accentColor.opacity(0.6)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )

            Text("Ready to Get Started?")
              .font(.system(size: 28, weight: .bold, design: .rounded))
              .foregroundColor(.primary)

            Text("Start your first conversation and experience AI with confidence scores")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
          }

          Button(action: {
            createNewChat()
          }) {
            HStack(spacing: 12) {
              Image(systemName: "plus.circle.fill")
                .font(.system(size: 20, weight: .semibold))
              Text("Get Started")
                .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: 280)
            .padding(.vertical, 16)
            .background(
              LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .cornerRadius(16)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
          }
          .buttonStyle(.plain)

          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
      } else {
        HistoryView(selectedConversation: $selectedConversation)
      }
    } detail: {
      if let conversation = selectedConversation {
        ChatView(conversation: conversation)
      } else {
        VStack(spacing: 20) {
          Image(systemName: "bubble.left.and.bubble.right")
            .font(.system(size: 60))
            .foregroundStyle(.tint)
          Text("Select or start a new chat")
            .font(.title2)
            .foregroundColor(.secondary)
        }
      }
    }
    .onAppear {
      // Show onboarding if user hasn't completed it and has no conversations
      if !hasCompletedOnboarding && conversations.isEmpty {
        // Small delay for smooth appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          showOnboarding = true
        }
      }
    }
    .fullScreenCover(isPresented: $showOnboarding) {
      OnboardingView(isPresented: $showOnboarding)
        .onDisappear {
          hasCompletedOnboarding = true
        }
    }
  }

  private func createNewChat() {
    let newChat = Conversation(title: "New Chat")
    modelContext.insert(newChat)
    selectedConversation = newChat
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Conversation.self, inMemory: true)
    .environmentObject(LLMService())
}
